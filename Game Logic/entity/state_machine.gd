extends Node
class_name GenericStateMachine
#all from https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/

@export var initial_state:State = null
@onready var current_state:State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0) as State
).call()

func _ready() -> void:
	for state: State in find_children("*", "State"):
		state.connect("transition_please", Callable(self, "set_state"))
	
	await owner.ready
	current_state.enter("")

func _process(delta: float) -> void:
	current_state.update(delta)

func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)

func set_state(new_state:String, data:Dictionary = {}) -> void:
	if not has_node(new_state):
		push_warning("StateMachine: State '%s' does not exist." % new_state)
		return

	current_state.exit()
	var old_state := current_state
	current_state = get_node(new_state)
	current_state.enter(old_state.name, data)

func _unhandled_input(event: InputEvent) -> void:
	current_state.consume_input(event)
