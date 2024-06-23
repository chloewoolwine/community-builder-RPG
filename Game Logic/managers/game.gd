extends Node2D

#System Managers
@onready var world_manager = $WorldManager
@onready var entity_manager = $EntityManager
@onready var pickup_manager = $PickupManager
@onready var story_manager = $StoryManager
@onready var saver_loader = $SaverLoader
@onready var player = $EntityManager/Player

#UI
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

@export var debug = false

func _ready() -> void:
	#TODO: make a "fresh game" resource save so i dont have to worry about chagning this
	saver_loader.world = world_manager.world_data
	saver_loader.player = player
	saver_loader.story = story_manager.story_data
	
	
	#this should work OK as long as i do it after the world is fully loaded
	handle_inventory_setup()
	handle_entity_setup()
	
func handle_entity_setup():
	#for node in get_tree().get_nodes_in_group("dialogue"):
	#	node.toggle_menu.connect(toggle_dialogue)
	pass
	
func handle_inventory_setup():
	inventory_interface.set_player_inventory_data(player.inventory_data, player)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	player.toggle_menu.connect(toggle_inventory_interface)
	
	#chests + crafting tables (+ entities?)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_menu.connect(toggle_inventory_interface)

func toggle_inventory_interface(external_inventory_owner = null, _isPerson = false) -> void:
	inventory_interface.visible = !inventory_interface.visible
	hot_bar_inventory.visible = !inventory_interface.visible
	
	#if this did not come from the player and we're opening it 
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
		if debug:
			print("external inventory toggled")
	else: 
		inventory_interface.clear_external_inventory()

func toggle_dialogue(external_dialogue) -> void:
	print("dialogue box here!")
