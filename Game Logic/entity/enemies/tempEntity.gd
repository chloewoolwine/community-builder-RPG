extends Node2D
class_name TempEntity

signal toggle_menu(entity: TempEntity)

# Called when the node enters the scene tree for the first time.
func player_interact() -> void:
	toggle_menu.emit(self)
