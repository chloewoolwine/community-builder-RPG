extends PlayerState
#despite it's name, force jump handles falling too
#this state is used to jump to higher elevations
var target_global_loc:Vector2
var location:Location
var free:bool = false
var targ:Sprite2D

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	target_global_loc = data.get("target_global_loc", null)
	location = data.get("location", null)
	if target_global_loc == null:
		push_error("StateForceJump: No target_global_loc provided in data dictionary.")
		transition_please.emit(PlayerState.IDLE, self)
		return
	if location == null:
		push_error("StateForceJump: No location provided in data dictionary.")
		transition_please.emit(PlayerState.IDLE, self)
		return
	free = false
	player.elevation_handler.empty_collision_layer()
	player.animation_handler.animation_player.animation_finished.connect(_on_animation_finished)
	machine.print_if_debug("Entered state ForceJump")
	if machine.debug:
		targ = player.find_child("target")
		if targ != null:
			targ.visible = true
			targ.global_position = target_global_loc
			targ.self_modulate = Color.YELLOW_GREEN

func exit() -> void:
	super.exit()
	end_special_collisions() 
	player.animation_handler.animation_player.animation_finished.disconnect(_on_animation_finished)
	machine.print_if_debug("Exited state ForceJump")
	if targ != null:
		targ.visible = false

func physics_update(_delta: float) -> void:
	if targ != null:
		targ.visible = true
		targ.global_position = target_global_loc
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
	await get_tree().create_timer(0.3).timeout
	var input := get_curr_input()
	if input == Vector2i.ZERO:
		transition_please.emit(PlayerState.IDLE, self)
	else:
		transition_please.emit(PlayerState.WALK, self, {"input_vector": input})
	return

	
func _on_animation_finished(anim_name: String) -> void:
	#print("aniamtion finsihed from state_jump")
	if anim_name.begins_with(PlayerState.JUMP):
		machine.print_if_debug("StateForceJump: Jump animation finished, transitioning to Fall state.")
		_on_jump_finished()

func end_special_collisions() -> void: 
	player.elevation_handler.set_to_elevation_at_loc(location)
	for e in player.get_collision_exceptions():
		player.remove_collision_exception_with(e)
