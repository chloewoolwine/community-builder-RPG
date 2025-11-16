extends Node
class_name State

signal transition_please(target_state:String, data: Dictionary)

@export var input_consumer:bool = false

var animation_name:String = "Idle"
var enabled:bool = false

func enter(prev_state: String, data:Dictionary = {}) -> void:
	enabled = true

func exit() -> void:
	enabled = false

func consume_input(event: InputEvent) -> void: 
	if !input_consumer:
		return

func update(_delta:float) -> void:
	if !enabled:
		return

func physics_update(_delta:float) -> void:
	if !enabled:
		return
