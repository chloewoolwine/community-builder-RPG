extends PlayerState

var fall_time: float = .3
var target_global_loc:Vector2
var location:Location
var elevation_diff:int
var free:bool = false

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	target_global_loc = data.get("target_global_loc", null)
	location = data.get("location", null)
	if target_global_loc == null:
		push_error("StateForceFall: No target_global_loc provided in data dictionary.")
		transition_please.emit(PlayerState.IDLE, self)
		return
	if location == null:
		push_error("StateForceFall: No location provided in data dictionary.")
		transition_please.emit(PlayerState.IDLE, self)
		return
	elevation_diff = data.get("elevation_diff", -10000)
	if elevation_diff == -10000:
		push_error("StateForceFall: No elevation_diff provided in data dictionary.")
		transition_please.emit(PlayerState.IDLE, self)
		return
	free = false
	player.elevation_handler.empty_collision_layer()
	player.animation_handler.jump_finished.connect(_on_jump_finished)
	machine.print_if_debug("Entered StateForceFall")

func exit() -> void:
	super.exit()
	#if !free:
		#we never made it! oh no :/
	end_special_collisions() 
	player.animation_handler.jump_finished.disconnect(_on_jump_finished)
	machine.print_if_debug("Exited StateForceFall")

func physics_update(_delta: float) -> void:
	if !free && player.elevation_handler.trueloc.global_position.distance_to(target_global_loc) > 5.0:
		var direction:Vector2 = (target_global_loc - player.elevation_handler.trueloc.global_position).normalized()
		player.velocity_handler.move_to(direction)
		player.velocity_handler.do_physics(_delta)
	else:
		if !free:
			end_special_collisions() 
			free = true
		var input:Vector2i = get_curr_input()
		configure_facing(input)
		#print("falling with input: ", input)
		player.velocity_handler.move_to(input)
		player.velocity_handler.do_physics(_delta)

func _on_jump_finished() -> void:
	player.animation_handler.travel_to_and_blend(PlayerState.FALL, player.facing)
	await get_tree().create_timer(fall_time * elevation_diff).timeout
	var input := get_curr_input()
	machine.print_if_debug("animation done, emitting transition from StateForceFall")
	if input == Vector2i.ZERO:
		transition_please.emit(PlayerState.IDLE, self, {"caller": "StateForceFall"})
	else:
		transition_please.emit(PlayerState.WALK, self, {"input_vector": input, "caller": "StateForceFall"})
	return

func end_special_collisions() -> void: 
	player.elevation_handler.set_to_elevation_at_loc(location)
	for e in player.get_collision_exceptions():
		player.remove_collision_exception_with(e)
