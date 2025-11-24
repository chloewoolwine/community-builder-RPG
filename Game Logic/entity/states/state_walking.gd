extends PlayerState
class_name StateWalking

var input:Vector2i = Vector2i.ZERO

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	var input_vector:Vector2 = data.get("input_vector", Vector2.ZERO)
	input = input_vector
	configure_facing(input)
	player.velocity_handler.move_to(input_vector)
	player.animation_handler.travel_to_and_blend(PlayerState.WALK, player.facing)
	machine.print_if_debug("Entered StateWalking")

func exit() -> void:
	super.exit() #i don't think anything is needed here? 
	machine.print_if_debug("Exited StateWalking")

func physics_update(_delta: float) -> void:
	input = get_curr_input()
	if input == Vector2i.ZERO:
		machine.print_if_debug("StateWalking: input zero, dying to idle")
		transition_please.emit(PlayerState.IDLE, self)
		return
	configure_facing(input)
	#machine.print_if_debug("walking with input: ", input)
	player.animation_handler.travel_to_and_blend(PlayerState.WALK, player.facing)
	player.velocity_handler.move_to(input)
	player.velocity_handler.do_physics(_delta)

func consume_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_menu"):
		transition_please.emit(PlayerState.MENU, self, {"type":"inventory"})
	elif event.is_action_pressed("option_menu"):
		transition_please.emit(PlayerState.MENU, self, {"type":"options"})
	elif event.is_action_pressed("jump"):
		transition_please.emit(PlayerState.JUMP, self, {"input": input})
	elif event.is_action_pressed("action"):
		#TODO: maybe a state action in the future when i have animations
		var action_result := player.player_action_handler.do_action()
		if action_result == "chest":
			transition_please.emit(PlayerState.MENU, self, {"type":"chest"})
			return
		elif action_result == "entity":
			transition_please.emit(PlayerState.MENU, self, {"type":"entity"})
			return
