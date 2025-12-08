extends Control
class_name OptionsInterface

signal please_save_game()
signal unstuck_player()
@onready var save: Button = $Panel/MarginContainer/VBoxContainer/Save
@onready var loader: Button = $Panel/MarginContainer/VBoxContainer/Load
@onready var unstuck: Button = $Panel/MarginContainer/VBoxContainer/Unstuck
@onready var quit: Button = $Panel/MarginContainer/VBoxContainer/Quit

func _on_save_button_pressed() -> void:
	print("game save button pressed from options menu")
	please_save_game.emit()


func _on_quit_pressed() -> void:
	pass # Replace with function body.

func _on_unstuck_pressed() -> void:
	print("stuck player pressed")
	unstuck_player.emit()


func _on_load_pressed() -> void:
	pass # Replace with function body.
