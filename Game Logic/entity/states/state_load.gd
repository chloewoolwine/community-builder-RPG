extends PlayerState
class_name StateLoad

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	machine.print_if_debug("Entered StateLoad")
	#eh?

func exit() -> void:
	super.exit()
	machine.print_if_debug("Exited StateLoad")

func loading_done() -> void: 
	transition_please.emit(PlayerState.IDLE, self)
