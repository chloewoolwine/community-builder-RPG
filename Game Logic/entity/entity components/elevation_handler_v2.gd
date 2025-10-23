extends Node
class_name ElevationHandler

@export var entity:PhysicsBody2D
@export var things_to_offset: Array[Node2D] #this plus all its children are offset based on elevation

var current_elevation:int = 0:
	set(value):
		# print("setting elevation in EH of ", entity.name)
		_change_collision_layer(current_elevation, value)
		current_elevation = value
		_offset_sprites()

func _offset_sprites() -> void:
	#todo... some kind of animation thing needs to happen .>.
	#tween or something
	for sprite in things_to_offset:
		sprite.position.y = current_elevation * Constants.ELEVATION_Y_OFFSET

func _change_collision_layer(prev: int, new: int) -> void:
	entity.set_collision_mask_value(prev+10, false)
	entity.set_collision_mask_value(new+10,true)
