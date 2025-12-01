extends Control
class_name OptionsInterface

signal please_save_game()
@onready var save: Button = $Panel/VBoxContainer/Button

func _on_save_button_pressed() -> void:
	print("game save button pressed from options menu")
	please_save_game.emit()
