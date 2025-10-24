extends Node
class_name ObjElevationHandler

@export var parent:Node2D
@export var things_to_offset: Array[Node2D] #this plus all its children are offset based on elevation

func _ready() -> void:
	if parent == null:
		if get_parent() is Node2D:
			parent = get_parent()
		else:
			print(str("Warning! ObjElevationHandler found without Node2D parent in ", get_parent().name))
			self.queue_free()
	if things_to_offset.is_empty():
		var children := parent.get_children()
		for child in children:
			if child is Node2D:
				things_to_offset.append(child)
	_offset_sprites()
	_change_collision_layer(0, current_elevation)

var current_elevation:int = 0:
	set(value):
		# print("setting elevation in OEH of ", parent.name)
		#_change_collision_layer(current_elevation, value)
		current_elevation = value
		#_offset_sprites()

func _offset_sprites() -> void:
	#if parent != null:
	#	print("offsetting sprites of ", parent.name)
	for sprite in things_to_offset:
		sprite.position.y = current_elevation * Constants.ELEVATION_Y_OFFSET

func _change_collision_layer(prev: int, new: int) -> void:
	for thing in things_to_offset:
		if thing is PhysicsBody2D:
			thing.set_collision_mask_value(prev+10, false)
			thing.set_collision_mask_value(new+10,true)
