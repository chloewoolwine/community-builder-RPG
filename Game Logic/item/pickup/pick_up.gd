extends Area2D
class_name PickUp

@export var slot_data: SlotData

@onready var sprite_2d:Sprite2D = $Sprite2D

var flight_direction : int = 0

func _ready() -> void:
	if !slot_data:
		self.queue_free()
		if self.get_parent().get_parent().debug:
			push_error("Pickup instantiated without SlotData")
			print("Error: Pickup instantiated without SlotData")
	sprite_2d.texture = slot_data.item_data.texture
	flight_direction = randi_range(0, 3)

func _physics_process(_delta:float) -> void:
	pass #TODO: cute animation here while it waits to be picked up

#TODO: this should be opposite- it should look for the players hurt box/pickup box (an area) to enter
#this will make it easier for items to be picked up.
func _on_body_entered(body:Node2D) -> void:
	if self.get_parent().get_parent().debug:
		print("body entered, pickup registered")
	
	if body.inventory_data.pick_up_slot(slot_data):
		self.queue_free()
	
