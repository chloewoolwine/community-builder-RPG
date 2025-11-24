extends PlayerState
class_name StateIdle

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	player.animation_handler.travel_to_and_blend(PlayerState.IDLE, player.facing)
	player.velocity_handler.purge_speed()
	player.velocity_handler.stop()
	machine.print_if_debug("Entered StateIdle")

func exit() -> void:
	super.exit()
	machine.print_if_debug("Exited StateIdle")

func consume_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_menu"):
		transition_please.emit(PlayerState.MENU, self, {"type":"inventory"})
	elif event.is_action_pressed("option_menu"):
		transition_please.emit(PlayerState.MENU, self, {"type":"options"})
	elif event.is_action_pressed("jump"):
		transition_please.emit(PlayerState.JUMP, self)
	elif event.is_action_pressed("action"):
		#TODO: maybe a state action in the future when i have animations
		var action_result := player.player_action_handler.do_action()
		if action_result == "chest":
			transition_please.emit(PlayerState.MENU, self, {"type":"chest"})
			return
		elif action_result == "entity":
			transition_please.emit(PlayerState.MENU, self, {"type":"entity"})
			return

	#it's not any of the special ones, might just be movement: 
	var input_vector := Vector2i.ZERO
	if event.is_action_pressed("up"):
		input_vector.y = -1
	if event.is_action_pressed("down"):
		input_vector.y = 1
	if event.is_action_pressed("left"):
		input_vector.x = -1
	if event.is_action_pressed("right"):
		input_vector.x = 1

	if input_vector != Vector2i.ZERO:
		#print("inputvector: ", input_vector)
		transition_please.emit(PlayerState.WALK, self, {"input_vector": input_vector})
		return
