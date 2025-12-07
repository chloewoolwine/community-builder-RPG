extends PlayerState

@export var up_area:Area2D
@export var down_area:Area2D
@export var right_area:Area2D
@export var left_area:Area2D

signal jump_start()
var jump_time: float = 0.7
var input:Vector2i = Vector2i.ZERO
var checked_bodies: Array = []
var timer: SceneTreeTimer
var eleh:ElevationHandler

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
	eleh = player.elevation_handler
	machine.print_if_debug("Entered StateJump")
	up_area.collision_mask = 0
	up_area.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)
	down_area.collision_mask = 0
	down_area.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)
	right_area.collision_mask = 0
	right_area.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)
	left_area.collision_mask = 0
	left_area.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)
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
	#check different area depending on dir
	var jump_area:Area2D
	if player.facing.y != 0:
		if player.facing.y < 0:
			jump_area = up_area
		else:
			jump_area = down_area
	elif player.facing.x != 0:
		if player.facing.x > 0:
			jump_area = right_area
		else:
			jump_area = left_area
	if jump_area != null:
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
		var trh := body.get_parent().get_parent().get_parent() as TerrainRulesHandler
		var true_loc := player.elevation_handler.get_true_loc()
		#this doesn't take direction into account, causing Problems....
		if body.name == "Base":
			pass #taking this out for now because it's causing issues - i want this out by end of year
			#TODO: see i if can make lower jumps work somehow. maybe only block certain ones. 
			#validate_lower_jump(true_loc, player.elevation_handler.current_elevation, trh)
		elif body.name == "HigherElevationWarner":
			#higher jump position
			validate_higher_jump(true_loc, player.elevation_handler.current_elevation, trh)
		elif body.name == "WaterMapper":
			#water- should only happen after base is found
			pass
	elif body.get_parent().is_in_group("jumpable") || body.is_in_group("jumpable"):
		#body.add_collision_exception_with(jump_area) TODO: this doesn't make any sense- need the collider
		machine.print_if_debug("Collided with jumpable object: " + body.name)
		#jumped onto a jumpable object

func validate_lower_jump(true_loc: Location, elevation: int, trh: TerrainRulesHandler) -> void:
	var loc_other := true_loc.get_location(input)
	var sd_other := trh.get_square_data_at_location(loc_other)
	if sd_other.water_saturation >= Constants.SHALLOW_WATER:
		#not dealing with this yet lol 
		return
	var diff := player.elevation_handler.current_elevation - sd_other.elevation
	var targ := Vector2(input * Constants.TILE_SIZE) + eleh.get_assumed_pos() - Vector2(0, diff * Constants.ELEVATION_Y_OFFSET)
	if check_obstacles_at_point(targ, sd_other.elevation):
		machine.print_if_debug("StateJump: Obstacle detected at higher elevation jump target, cannot jump there.")
		return
	machine.print_if_debug("StateJump: Base collision elevation difference: " + str(diff))
	transition_please.emit(PlayerState.FORCEFALL, self, {"target_global_loc": targ, "location": loc_other, "elevation_diff": diff})
	#TODO: some way of determining how long/how to animate the fall properly 

func validate_higher_jump(true_loc: Location, elevation: int, trh: TerrainRulesHandler) -> void:
	var loc_other := true_loc.get_location(input)
	var sd_other := trh.get_square_data_at_location(loc_other) #TODO: I NEED to get square data somehow else. this is not testable!
	if sd_other and sd_other.elevation == player.elevation_handler.current_elevation+1:
		var targ := Vector2(input * Constants.TILE_SIZE) + eleh.get_assumed_pos()
		#print("target: " + str(targ))
		if check_obstacles_at_point(targ, sd_other.elevation):
			machine.print_if_debug("StateJump: Obstacle detected at higher elevation jump target, cannot jump there.")
			return
		machine.print_if_debug("StateJump: Valid higher elevation jump found to loc " + str(loc_other))
		transition_please.emit(PlayerState.FORCEJUMP, self, {"target_global_loc": targ, "location": loc_other})

## WARNING: i wrote this when i was sick (my tummy hurts)
func check_obstacles_at_point(global_point: Vector2, elevation: int) -> bool:
	var space_state := player.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(eleh.get_assumed_pos(), global_point, 1 << (elevation + 9), [player.get_rid()])
	var result := space_state.intersect_ray(query)
	machine.print_if_debug("checking obstacles at point: "+ str(global_point) + " elevation: "+ str(elevation) + " result: "+ str(result))
	if result.size() > 0 && (result.collider.name == "Base" || result.collider.name == "HigherElevationWarner"): #should be! 
		var new_query := PhysicsRayQueryParameters2D.create(eleh.get_assumed_pos(), global_point, 1 << (elevation + 9), [player.get_rid(), result.rid])
		machine.print_if_debug('excluding: '+ str(new_query.exclude))
		result = space_state.intersect_ray(new_query)
	machine.print_if_debug("checking obstacles at point: "+ str(global_point) + " elevation: "+ str(elevation) + " result: "+ str(result))
	if result.size() > 0:
		machine.print_if_debug("new result: " + str(result))
		return true
	return false
