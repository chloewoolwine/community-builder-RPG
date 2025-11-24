extends PlayerState

@export var jump_area:Area2D
signal jump_start()
var jump_time: float = 0.7
var input:Vector2i = Vector2i.ZERO
var checked_bodies: Array = []
var timer: SceneTreeTimer

func _ready() -> void:
	super._ready()
	#jump_area.body_entered.connect(_on_jump_area_body_entered)

func enter(prev_state: String, data:Dictionary = {"input": Vector2i.ZERO}) -> void:
	super.enter(prev_state, data)
	jump_start.emit()
	if "jump_time" in player:
		jump_time = player.jump_time
	player.animation_handler.travel_to_and_blend(PlayerState.JUMP, player.facing)
	timer = get_tree().create_timer(jump_time)
	input = data.get("input", Vector2i.ZERO)
	machine.print_if_debug("Entered StateJump")
	jump_area.collision_mask = 0
	jump_area.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)
	#print("Jump area collision mask set to: ", jump_area.collision_mask)

func exit() -> void:
	super.exit()
	checked_bodies.clear()
	machine.print_if_debug("Exited StateJump")

func physics_update(_delta: float) -> void:
	input = get_curr_input()
	configure_facing(input)
	#print("jumping with input: ", input)
	player.animation_handler.travel_to_and_blend(PlayerState.JUMP, player.facing)
	player.velocity_handler.move_to(input)
	player.velocity_handler.do_physics(_delta)
	for body in jump_area.get_overlapping_bodies():
		#print("body.name: ", body.name)
		if body not in checked_bodies:
			check_overlapping_body(body)
			checked_bodies.append(body)
	if timer.time_left <= 0.0:
		#jump complete
		transition_please.emit(PlayerState.FALL, self)

func check_overlapping_body(body: Node) -> void:
	if body is TileMapLayer:
		machine.print_if_debug("Collided with tilemap layer: " + body.name + " ensuring valid jump")
		var el := body.get_parent() as ElevationLayer
		var trh := el.get_parent().get_parent() as TerrainRulesHandler
		var true_loc := player.elevation_handler.get_true_loc()
		if body.name == "Base":
			var loc_other := true_loc.get_location(input)
			var sd_other := trh.get_square_data_at_location(loc_other)
			if sd_other.water_saturation >= Constants.SHALLOW_WATER:
				#not dealing with this yet lol 
				return
			var diff := player.elevation_handler.current_elevation - sd_other.elevation
			machine.print_if_debug("StateJump: Base collision elevation difference: " + str(diff))
			var targ := EnvironmentLogic.get_real_pos_object(loc_other, 0) #TODO; once we have checking, more better
			transition_please.emit(PlayerState.FORCEFALL, self, {"target_global_loc": targ, "location": loc_other, "elevation_diff": diff})
			#ledge of the layer we are on
			#TODO: 
				#Check the height difference
				#TODO: some way of determining how long/how to animate the fall properly 
				#if valid, transition to ForceFall state=
			pass
		elif body.name == "HigherElevationWarner":
			#higher jump position
			var loc_other := true_loc.get_location(input)
			var sd_other := trh.get_square_data_at_location(loc_other)
			if sd_other and sd_other.elevation == player.elevation_handler.current_elevation+1:
				#THE PLAN:
					#ensure the target tile is clear of objects
					#- NOT DONE check for overlapping bodies at that tile position
					#- NOT DONE check it's not water 
					#- DONE IF all clear, activate FALLING IMMEDIATELY
				machine.print_if_debug("StateJump: Valid higher elevation jump found to loc " + str(loc_other))
				#this gets the center of the tile. once we have checking, we can make this straight
				#in the direction of the player's last input (as long as the space is clear)
				var targ := EnvironmentLogic.get_real_pos_object(loc_other, 0)
				transition_please.emit(PlayerState.FORCEJUMP, self, {"target_global_loc": targ, "location": loc_other})
		elif body.name == "WaterMapper":
			#water- should only happen after base is found
			pass
	elif body.get_parent().is_in_group("jumpable") || body.is_in_group("jumpable"):
		body.add_collision_exception_with(jump_area)
		machine.print_if_debug("Collided with jumpable object: " + body.name)
		#jumped onto a jumpable object
