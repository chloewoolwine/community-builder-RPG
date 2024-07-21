extends Node
class_name PickupManager

const PICK_UP = preload("res://Scenes/objects/pick_up.tscn")
@onready var player:Player = $"../EntityManager/Player"

func _on_inventory_interface_drop_slot_data_into_world(slot_data:SlotData) -> void:
	var new_pick_up:PickUp = PICK_UP.instantiate()
	new_pick_up.slot_data = slot_data
	#TODO: cute toss animation
	new_pick_up.position = player.get_raycast_target()
	add_child(new_pick_up)
	player.print_if_debug("item dropped at %v", new_pick_up.position)
 
func generate_pickups_from_list(location:Vector2, list: Array[ItemData]) -> void:
	for data in list:
		var new_pick_up := PICK_UP.instantiate()
		new_pick_up.slot_data = SlotData.new()
		new_pick_up.slot_data.item_data = data
		new_pick_up.global_position = location
		add_child(new_pick_up)
