extends Resource
class_name Location

@export var chunk: Vector2i
@export var position: Vector2i

func _init(pos: Vector2i, chun: Vector2i) -> void:
	chunk = chun
	position = pos

func equals(other: Location) -> bool: 
	return other.chunk == self.chunk and other.position == self.position
