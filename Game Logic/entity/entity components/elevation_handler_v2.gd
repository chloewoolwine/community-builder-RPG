extends Node
class_name ElevationHandler

@export var entity:PhysicsBody2D
@export var trueloc: Sprite2D 
@export var offsettees: Array[Node]
var terrain_rules_handler: TerrainRulesHandler
var original_positions: Array[float]

var current_elevation:int = 0:
	set(value):
		print("setting elevation in EH of ", entity.name, " old: ", current_elevation, " new: ", value)
		_change_collision_layer(current_elevation, value)
		var old:= current_elevation
		current_elevation = value
		_offset_sprites(old)
		
func _ready() -> void:
	#print(trueloc)
	#print(offsettees)
	for off in offsettees:
		original_positions.append(off.position.y)

func _offset_sprites(old: int) -> void:
	#todo... some kind of animation thing needs to happen .>.
	#tween or something
	#print("offsetting sprites")
	for x in range(offsettees.size()):
		var off := offsettees[x]
		#print(off.name)
		off.position.y = (current_elevation * Constants.ELEVATION_Y_OFFSET) + original_positions[x]
		if off is HitBox:
			off.set_collision_layer_value(old+10, false)
			off.set_collision_layer_value(current_elevation+10, true)

func _change_collision_layer(prev: int, new: int) -> void:
	entity.set_collision_mask_value(prev+10, false)
	entity.set_collision_mask_value(new+10,true)

func empty_collision_layer() -> void:
	entity.set_collision_mask_value(current_elevation+10, false)

func get_true_loc() -> Location:
	if terrain_rules_handler == null:
		push_warning("ElevationHandler: terrain_rules_handler is null in get_true_loc()!")
		return null
	var base_pos: Vector2 = terrain_rules_handler.get_base_pos_from_global(trueloc.global_position)
	return Location.get_location_from_world(base_pos)

func set_to_elevation_at_loc(loc: Location) -> void:
	if terrain_rules_handler == null:
		push_warning("ElevationHandler: terrain_rules_handler is null in set_to_elevation_at_loc()!")
		return
	#TODO: maybe change this, its real hard to test
	var square_data: SquareData = terrain_rules_handler.get_square_data_at_location(loc)
	if square_data == null:
		push_warning("ElevationHandler: square_data is null for loc %s in set_to_elevation_at_loc()!" % loc)
		return
	current_elevation = square_data.elevation
	#_offset_sprites()

func get_assumed_pos() -> Vector2:
	return entity.global_position + Vector2(0, current_elevation * Constants.ELEVATION_Y_OFFSET)
