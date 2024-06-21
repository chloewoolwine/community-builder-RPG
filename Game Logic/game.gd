extends Node2D

@onready var player = $EntityManager/Player
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

@export var debug = false

#TODO: move this to entity manager?
func _ready() -> void:
	inventory_interface.set_player_inventory_data(player.inventory_data, player)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	player.toggle_menu.connect(toggle_inventory_interface)
	
	#inventory_interface.set_chest_inventories(save.chest)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_menu.connect(toggle_inventory_interface)
	#for node in get_tree().get_nodes_in_group("interactable"):
	#	node.toggle_menu.connect(toggle_dialogue)

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
