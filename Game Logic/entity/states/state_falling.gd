extends PlayerState

var input:Vector2i = Vector2i.ZERO
var fall_time: float = 0.4 #TBD! not sure the logic for determining this yet
#probably more height = more fall

func enter(prev_state: String, data:Dictionary = {"input": Vector2i.ZERO}) -> void:
	super.enter(prev_state, data)
	player.animation_handler.travel_to_and_blend(PlayerState.FALL, player.facing)
	get_tree().create_timer(fall_time).timeout.connect(func() -> void:
		input = get_curr_input()
		if input == Vector2i.ZERO:
			transition_please.emit(PlayerState.IDLE, self)
		else:
			transition_please.emit(PlayerState.WALK, self, {"input_vector": input})
	)
	input = data.get("input", Vector2i.ZERO)
	machine.print_if_debug("Entered StateFalling")

func exit() -> void:
	super.exit()
	machine.print_if_debug("Exited StateFalling")
	for e in player.get_collision_exceptions():
		player.remove_collision_exception_with(e)

func physics_update(_delta: float) -> void:
	input = get_curr_input()
	configure_facing(input)
	#print("falling with input: ", input)
	player.animation_handler.travel_to_and_blend(PlayerState.FALL, player.facing)
	player.velocity_handler.move_to(input)
	player.velocity_handler.do_physics(_delta)
