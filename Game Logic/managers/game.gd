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
@onready var entity_manager:EntityManager = $EntityManager
@onready var pickup_manager:PickupManager = $PickupManager
@onready var story_manager:StoryManager = $StoryManager
@onready var saver_loader:SaverLoader = $SaverLoader
@onready var player:Player = $EntityManager/Player

#UI
@onready var inventory_interface:InventoryInterface = $UI/InventoryInterface
@onready var hot_bar_inventory:HotBarInventory = $UI/HotBarInventory
@onready var options_menu:OptionsInterface = $UI/OptionsMenu
@onready var entity_interface:EntityInterface = $UI/EntityInterface

func _ready() -> void:
	#TODO: make a "fresh game" resource save so i dont have to worry about chagning this
	saver_loader.world = world_manager.world_data
	saver_loader.player = player.player_data
	saver_loader.story = story_manager.story_data
	
	#this should work OK as long as i do it after the world is fully loaded
	handle_inventory_setup()
	handle_entity_setup()
	
func handle_entity_setup() -> void:
	for node in get_tree().get_nodes_in_group("entity_interactable"):
		node.toggle_menu.connect(toggle_entity_interface)
	
	entity_interface.close_dialogue.connect(toggle_entity_interface)
	
func handle_inventory_setup() -> void:
	inventory_interface.set_player_inventory_data(player.inventory_data, player)
	player.inventory_data.setOwner(player)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	player.toggle_menu.connect(toggle_inventory_interface)
	#TODO: link story data to DataTabs through inventory interface
	
	#chests + crafting tables (+ entities?)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_menu.connect(toggle_inventory_interface)
		
	player.toggle_options.connect(handle_options_press)
	gui_state = GuiState.WORLD
	
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
		else:
			gui_state = GuiState.WORLD

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
			

@warning_ignore("untyped_declaration")
func toggle_entity_interface(entity) -> void:
	entity_interface.visible = !entity_interface.visible
	hot_bar_inventory.visible = !hot_bar_inventory.visible
	
	if entity:
		entity_interface.setup_entity(entity)
	
	if entity_interface.visible:
		gui_state = GuiState.ENTITY
	else:
		gui_state = GuiState.WORLD
		player.toggle_menu_state()
