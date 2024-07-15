extends Node2D

signal toggle_menu(entity)

# Called when the node enters the scene tree for the first time.
func player_interact() -> void:
	toggle_menu.emit(self)
