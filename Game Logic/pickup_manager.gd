extends Node

const PICK_UP = preload("res://Game Logic/item/pickup/pick_up.tscn")
@onready var player = $"../EntityManager/Player"

func _on_inventory_interface_drop_slot_data_into_world(slot_data):
	var new_pick_up = PICK_UP.instantiate()
	new_pick_up.slot_data = slot_data
	#TODO: cute toss animation
	new_pick_up.position = player.get_raycast_target()
	add_child(new_pick_up)
	player.print_if_debug("item dropped at %v", new_pick_up.position)
 
