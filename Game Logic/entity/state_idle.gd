extends State
class_name StateIdle

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	animation_name = "Idle"
	#print("Entered StateIdle")

func exit() -> void:
	super.exit()
	#print("Exited StateIdle")

func consume_input(event: InputEvent) -> void:
	if !input_consumer:
		return 
	
