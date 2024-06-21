extends Area2D

@export var slot_data: SlotData

@onready var sprite_2d = $Sprite2D

func _ready():
	if !slot_data:
		if self.get_parent().get_parent().debug:
			push_error("Pickup instantiated without SlotData")
			print("Error: Pickup instantiated without SlotData")
		self.queue_free()
	sprite_2d.texture = slot_data.item_data.texture

func _physics_process(_delta):
	pass #TODO: cute animation here while it waits to be picked up

func _on_body_entered(body):
	if self.get_parent().get_parent().debug:
		print("body entered, pickup registered")
	
	if body.inventory_data.pick_up_slot(slot_data):
		self.queue_free()
	
