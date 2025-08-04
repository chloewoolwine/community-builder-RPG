extends Node2D
class_name GameGod

# ENUMS
enum GuiState{WORLD, INVENTORY, CHEST, ENTITY, OPTIONS}

# EXPORT VARS
@export var debug:bool = false

var gui_state: GuiState

# ONREADY VARS
#System Managers
@onready var world_manager:WorldManager = $WorldManager
# entity manager moved down the scene tree for proper y-sorting :c
@onready var entity_manager: EntityManager = $WorldManager/TerrainRulesHandler/ObjectAtlas/EntityManager
@onready var pickup_manager:PickupManager = $PickupManager
@onready var story_manager:StoryManager = $StoryManager
#@onready var saver_loader:SaverLoader = $SaverLoader
# player moved down the scene tree, also for y-aasorting :C
#@onready var player:Player = $EntityManager/Player
@onready var lighting:CalendarManager= $StoryManager/Lighting
@onready var player: Player = $WorldManager/TerrainRulesHandler/ObjectAtlas/EntityManager/Player

#UI
@onready var inventory_interface:InventoryInterface = $UI/InventoryInterface
@onready var hot_bar_inventory:HotBarInventory = $UI/HotBarInventory
@onready var options_menu:OptionsInterface = $UI/OptionsMenu
@onready var entity_interface:EntityInterface = $UI/EntityInterface

var game_ready: bool = false

func _ready() -> void:
	#TODO: make a "fresh game" resource save so i dont have to worry about chagning this
	#saver_loader.world = world_manager.world_data
	#saver_loader.player = player.player_data
	#saver_loader.story = story_manager.story_data
	
	#this should work OK as long as i do it after the world is fully loaded
	handle_inventory_setup()
	handle_entity_setup()
	handle_player_setup()
	handle_world_setup()
	
	handle_final_presentation()

## TURNS ON THE SPICE! After everything else has finished loading. 
func handle_final_presentation() -> void: 
	## TODO: make some juice here, like a fade in from black :D 
	await get_tree().create_timer(5).timeout
	lighting.proccessTime = true
	player.state = Player.PlayerStates.STATE_IDLE
	game_ready = true

## Connects events dynamically
func handle_world_setup() -> void:
	world_manager.trh.object_atlas.plant_placed.connect(connect_plant_to_sky)
	world_manager.player = player
	lighting.time_tick.connect(world_manager.water_timer)
	world_manager.do_setup()

## Connects plants with the world so they can grow
func connect_plant_to_sky(plant: GenericPlant) -> void:
	plant.spawn_pickups.connect(pickup_manager.generate_pickups_from_list)
	plant.plant_component.propagate_plant.connect(world_manager.manage_propagation_success)
	lighting.time_tick.connect(plant.plant_component.minute_pass)

#for when I have Hungry Hungry entities spawning, they need to know when we are paused
func connect_entity_to_player() -> void:
	pass

## Connects events involving the playe
func handle_player_setup() -> void:
	player.health_changed.connect(hot_bar_inventory.update_health)
	player.health_handler.health_zero.connect(player_died)
	player.tile_indicator.move_me.connect(world_manager.move_indicator)
	player.tile_indicator.placement.connect(world_manager.place_object)
	player.tile_indicator.modify.connect(world_manager.modify_tilemap)
	lighting.time_tick.connect(player.health_handler.hunger_tick)

## TODO: remove
## Connects events for already existing plants (growing + spawning pickups)
func handle_plant_setup() -> void:
	for node in get_tree().get_nodes_in_group("plant_growable"):
		node.spawn_pickups.connect(pickup_manager.generate_pickups_from_list)
		lighting.time_tick.connect(node.plant_component.minute_pass)
	
## Connects entity events (open entity menu and close dialogue)
## TODO: all of this needs to be dynamically done whenever an entity
## loads in to the game -> a lot like "connect plant to sky" for entities
func handle_entity_setup() -> void:
	for node in get_tree().get_nodes_in_group("entity_interactable"):
		node.toggle_menu.connect(toggle_entity_interface)
	for node in get_tree().get_nodes_in_group("elevation_handler"): 
		node.give_me_layer_please.connect(world_manager.give_requested_layer)
	for node in get_tree().get_nodes_in_group("hungerhealth"):
		node.player = player
	
	entity_interface.close_dialogue.connect(toggle_entity_interface)
	
## Connects inventory events
## 1. Sets up the inventory GUI & hotbar with the player's inventory data
## 2. Sets up the player's inventory toggle *and* pause menu toggle
## 3. Iteratively sets external_inventories inventory data (non-entity)
func handle_inventory_setup() -> void:
	inventory_interface.set_player_inventory_data(player.inventory_data, player)
	player.inventory_data.setOwner(player)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	lighting.time_tick.connect(hot_bar_inventory.update_circle)
	player.toggle_menu.connect(toggle_inventory_interface)
	#TODO: link story data to DataTabs through inventory interface
	
	#chests + crafting tables (+ entities?)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_menu.connect(toggle_inventory_interface)
		
	player.toggle_options.connect(handle_options_press)
	gui_state = GuiState.WORLD

## Toggles the pause menu
func handle_options_press() -> void:
	if gui_state == GuiState.INVENTORY || gui_state == GuiState.CHEST:
		toggle_inventory_interface()
	elif gui_state == GuiState.ENTITY:
		player.toggle_menu_state() #stay paused
	else: 
		hot_bar_inventory.visible = !hot_bar_inventory.visible
		options_menu.visible = !options_menu.visible
		
		if options_menu.visible:
			gui_state = GuiState.OPTIONS
			lighting.proccessTime = false
		else:
			gui_state = GuiState.WORLD
			lighting.proccessTime = true

## Turns on the inventory interface. Takes [param external_inventory_owner] as 
## the inventory to display and [param _isPerson] to distinguish between a chest 
## and an entity's inventory (unimplemented, possibly unused?)
@warning_ignore("untyped_declaration")
func toggle_inventory_interface(external_inventory_owner = null, _isPerson : bool = false) -> void:
	if gui_state == GuiState.OPTIONS || gui_state == GuiState.ENTITY:
		player.toggle_menu_state() #stay paused
	else: 
		inventory_interface.visible = !inventory_interface.visible
		hot_bar_inventory.visible = !inventory_interface.visible
		
		#if this did not come from the player and we're opening it 
		if external_inventory_owner and inventory_interface.visible:
			inventory_interface.set_external_inventory(external_inventory_owner)
		else: 
			inventory_interface.clear_external_inventory()
			
		if inventory_interface.visible:
			if external_inventory_owner:
				gui_state = GuiState.CHEST
			else:
				gui_state = GuiState.INVENTORY
		else:
			gui_state = GuiState.WORLD
			

## Turns on the entity GUI. Takes [param entity] for it's setup
func toggle_entity_interface(entity: Entity) -> void:
	entity_interface.visible = !entity_interface.visible
	hot_bar_inventory.visible = !hot_bar_inventory.visible
	
	if entity:
		entity_interface.setup_entity(entity)
	
	if entity_interface.visible:
		gui_state = GuiState.ENTITY
	else:
		gui_state = GuiState.WORLD
		player.toggle_menu_state()

func player_died() -> void:
	#do cool stuff here 
	player.state = Player.PlayerStates.STATE_DEAD
	await get_tree().create_timer(3).timeout
	## TERRIBLE IDEA need better spawn point Stat
	player.global_position = Vector2.ZERO - Vector2(100,100)
#	player.elevation_handler.current_elevation = 1 
	player.health_handler.change_health(50)
	player.health_handler.current_hunger = player.health_handler.max_hunger/2
	player.state = Player.PlayerStates.STATE_IDLE
	pass
		
# chat gpt generated name ideas lmao 
#Town of Bloom
#Rising Horizons
#Starlight Acres
#Sunrise Settlement
#Echoes of Eden
#Ashen Acres
#Last Garden
#Seeds of Tomorrow
#Hallowed Harvest
#Phoenix Grove
#Blooming Wastes
#Renewal Ridge
#Echoing Harvest
#Waking Grove
#The Last Orchard
#Twilight Tillage
#Eternal Springs
#Hallowed Harvest

#my ideas
# Twilight Bloom
# Star/Moonlight Grove
# Echoes of the Grove
# Twilight Grove <- WOW location
