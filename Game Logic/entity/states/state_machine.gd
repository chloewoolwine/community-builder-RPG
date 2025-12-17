extends Node
class_name GenericStateMachine
#all from https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/
signal state_change(new_state: State)
@export var initial_state:State = null
@export var debug:bool = false
@onready var current_state:State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0) as State
).call()

func _ready() -> void:
	for state: State in find_children("*", "State"):
		state.transition_please.connect(set_state)
	
	await owner.ready
	current_state.enter("")

func _process(delta: float) -> void:
	current_state.update(delta)

func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)

func set_state(new_state:String, calling_state: State, data:Dictionary = {}) -> void:
	if not has_node(new_state):
		push_warning("StateMachine: State '%s' does not exist." % new_state)
		return
	print_if_debug("new state: " + new_state + " old state " + current_state.name + " calling state: " + calling_state.name)
	if new_state == current_state.name:
		print("StateMachine: Current state is already '%s'." % new_state)
		push_warning("StateMachine: Attempted to transition to the same state '%s'." % new_state)
		return

	current_state.exit()
	var old_state := current_state
	current_state = get_node(new_state)
	current_state.enter(old_state.name, data)
	state_change.emit(current_state)

func _unhandled_input(event: InputEvent) -> void:
	current_state.consume_input(event)

func print_if_debug(msg: String) -> void:
	if debug:
		print(msg)
