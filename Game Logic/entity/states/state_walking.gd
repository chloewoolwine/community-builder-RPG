extends PlayerState
class_name StateWalking

@export var up_area:Area2D
@export var down_area:Area2D
@export var right_area:Area2D
@export var left_area:Area2D

var input:Vector2i = Vector2i.ZERO
var eleh:ElevationHandler

func enter(prev_state: String, data:Dictionary = {}) -> void:
	super.enter(prev_state, data)
	var input_vector:Vector2 = data.get("input_vector", Vector2.ZERO)
	input = input_vector
	eleh = player.elevation_handler
	configure_facing(input)
	player.velocity_handler.move_to(input_vector)
	player.animation_handler.travel_to_and_blend(PlayerState.WALK, player.facing)
	machine.print_if_debug("Entered StateWalking")
	
	var masks := [up_area, down_area, right_area, left_area]
	for mask:Area2D in masks:
		mask.collision_mask = 0
		mask.set_collision_mask_value(player.elevation_handler.current_elevation + 10, true)

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
			check_overlapping_body(body)

func check_overlapping_body(body: Node) -> void:
	if body is TileMapLayer && body.name == "Base":
		machine.print_if_debug("Collided with tilemap layer: " + body.name + " ensuring valid jump")
		#TODO: change this later to be a signal, this is dookie
		var trh := body.get_parent().get_parent().get_parent() as TerrainRulesHandler
		var true_loc := player.elevation_handler.get_true_loc()
		var loc_other := true_loc.get_location(input)
		var sd_other := trh.get_square_data_at_location(loc_other)
		if !sd_other:
			#this is hopefully and editor-only bug
			push_warning("player tried to jump onto a tile that does not exist")
			return
		if sd_other.water_saturation >= Constants.SHALLOW_WATER:
			#not dealing with this yet lol 
			return
		var diff := player.elevation_handler.current_elevation - sd_other.elevation
		var targ := Vector2(input * Constants.TILE_SIZE) + eleh.get_assumed_pos() - Vector2(0, diff * Constants.ELEVATION_Y_OFFSET)
		if check_obstacles_at_point(targ, sd_other.elevation):
			machine.print_if_debug("StateWalk: Obstacle detected at higher elevation jump target, cannot jump there.")
			return
		machine.print_if_debug("StateWalk: Base collision elevation difference: " + str(diff))
		transition_please.emit(PlayerState.FORCEFALL, self, {"target_global_loc": targ, "location": loc_other, "elevation_diff": diff, "caller":PlayerState.WALK})
		return

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
