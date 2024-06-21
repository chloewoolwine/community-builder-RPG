extends StaticBody2D

signal toggle_menu(external_inventory_owner)

@export var inventory_data: InventoryData

func _ready():
	inventory_data.setOwner(self)

func player_interact()-> void:
	toggle_menu.emit(self)
