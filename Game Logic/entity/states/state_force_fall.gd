extends PlayerState

var fall_time: float = .3
var target_global_loc:Vector2
var location:Location
var elevation_diff:int
var free:bool = false
var targ:Sprite2D

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
	machine.print_if_debug("Entered StateForceFall")
	if machine.debug:
		targ = player.find_child("target")
		if targ != null:
			targ.visible = true
			targ.global_position = target_global_loc
			targ.self_modulate = Color.BLUE_VIOLET
	var caller:String = data.get("caller", "")
	print("caller:", caller)
	if caller == PlayerState.WALK:
		print("caller is walk")
		player.animation_handler.travel_to_and_blend(PlayerState.FALL, player.facing)
		await get_tree().create_timer(fall_time * elevation_diff).timeout
		var input := get_curr_input()
		machine.print_if_debug("animation done, emitting transition from StateForceFall")
		if input == Vector2i.ZERO:
			transition_please.emit(PlayerState.IDLE, self, {"caller": "StateForceFall"})
		else:
			transition_please.emit(PlayerState.WALK, self, {"input_vector": input, "caller": "StateForceFall"})
		return
	else:
		player.animation_handler.animation_player.animation_finished.connect(_on_animation_finished)

func exit() -> void:
	super.exit()
	#if !free:
		#we never made it! oh no :/
	end_special_collisions()
	if player.animation_handler.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_handler.animation_player.animation_finished.disconnect(_on_animation_finished)
	machine.print_if_debug("Exited StateForceFall")
	if targ != null:
		targ.visible = false

func physics_update(_delta: float) -> void:
	if targ != null:
		targ.visible = true
		targ.global_position = target_global_loc
	if !free && player.elevation_handler.trueloc.global_position.distance_to(target_global_loc) > 5.0 :
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

func _on_animation_finished(anim_name: String) -> void:
	#print("aniamtion finsihed from state_jump")
	if anim_name.begins_with(PlayerState.JUMP):
		machine.print_if_debug("StateForceJump: Jump animation finished, transitioning to Fall state.")
		_on_jump_finished()

func end_special_collisions() -> void: 
	machine.print_if_debug("ending special collisions")
	player.elevation_handler.set_to_elevation_at_loc(location)
	for e in player.get_collision_exceptions():
		player.remove_collision_exception_with(e)
