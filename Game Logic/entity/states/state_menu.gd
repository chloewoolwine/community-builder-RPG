extends PlayerState

var prev_state: String = ""
var type: String = ""

func enter(_prev_state: String, _data:Dictionary = {}) -> void:
	super.enter(_prev_state, _data)
	tick_hunger = false
	prev_state = _prev_state
	player.velocity_handler.purge_speed()
	player.velocity_handler.stop()
	player.animation_handler.travel_to_and_blend(PlayerState.IDLE, player.facing)
	type = _data.get("type", null)
	if type == "inventory":
		player.toggle_menu.emit()
	elif type == "options":
		player.toggle_options.emit()
	#Note: chests + dialogues are opened up with do_action 
	# because they need to check for proximity first

	machine.print_if_debug("Entered StateMenu")

func exit() -> void:
	super.exit()
	machine.print_if_debug("Exited StateMenu")

func consume_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_menu"):
		if type == "inventory":
			player.toggle_menu.emit()
			transition_please.emit(prev_state, self)
	elif event.is_action_pressed("option_menu"):
		player.toggle_options.emit()
		transition_please.emit(prev_state, self)

func leave_options_menu() -> void:
	player.toggle_options.emit()
	transition_please.emit(prev_state, self)
