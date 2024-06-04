extends Node2D

@onready var player = $Player
@onready var inventory_interface = $UI/InventoryInterface

func _ready() -> void:
	inventory_interface.set_player_inventory_data(player.inventory_data)
	#inventory_interface.set_chest_inventories(save.chest)
