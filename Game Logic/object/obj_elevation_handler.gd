extends Node
class_name ObjElevationHandler

@export var things_to_offset: Array[Node2D] #this plus all its children are offset based on elevation
var original_positions:Array[float]
@export var current_elevation:int = 0

func _ready() -> void:
	for thing in things_to_offset:
		original_positions.append(thing.position.y)
	_offset_sprites()
	_change_collision_layer(0, current_elevation)

func _offset_sprites() -> void:
	#print("offsetting sprites of ", owner.object_id)
	for x in range(things_to_offset.size()):
		var sprite:Node2D = things_to_offset[x]
		sprite.position.y = (current_elevation * Constants.ELEVATION_Y_OFFSET) + original_positions[x]

func _change_collision_layer(prev: int, new: int) -> void:
	for thing in things_to_offset:
		if thing is PhysicsBody2D && thing.name == "Wall":
			thing.set_collision_layer_value(prev+10, false)
			thing.set_collision_layer_value(new+10,true)
			#print("collision layer: ", thing.collision_layer)
