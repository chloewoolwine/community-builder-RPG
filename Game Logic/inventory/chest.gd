extends StaticBody2D
class_name TempChest

@warning_ignore("untyped_declaration")
signal toggle_menu(external_inventory_owner)

@export var inventory_data: InventoryData

func _ready() -> void:
	inventory_data.setOwner(self)

func player_interact()-> void:
	toggle_menu.emit(self)
