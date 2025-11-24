extends Node
class_name State

@onready var machine: GenericStateMachine = get_parent() as GenericStateMachine

@warning_ignore("unused_signal")
signal transition_please(target_state:String, caller: State, data: Dictionary)


@warning_ignore("unused_parameter")
func enter(prev_state: String, data:Dictionary = {}) -> void:
	return

func exit() -> void:
	return

@warning_ignore("unused_parameter")
func consume_input(event: InputEvent) -> void: 
	return

func update(_delta:float) -> void:
	return

func physics_update(_delta:float) -> void:
	return
