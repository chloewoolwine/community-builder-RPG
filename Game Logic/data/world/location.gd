extends Resource
class_name Location

@export var chunk: Vector2i
@export var position: Vector2i

func _init(pos: Vector2i, chun: Vector2i) -> void:
	chunk = chun
	position = pos

func equals(other: Location) -> bool: 
	return other.chunk == self.chunk and other.position == self.position

## Please don't use this for distances more than a chunk away
func get_location(dir:Vector2i) -> Location:
	var pos := position + dir
	var chu := Vector2i(chunk.x, chunk.y)
	if pos.x >= 32:
		var diff := pos.x - 32
		pos.x = diff
		chu.x += 1
	elif pos.x < 0:
		var diff := 32 + pos.x
		pos.x = diff
		chu.x -= 1
	if pos.y >= 32: 
		var diff := pos.y - 32
		pos.y = diff
		chu.y += 1
	elif pos.y < 0: 
		var diff := 32 + pos.y
		pos.y = diff
		chu.y -= 1
	return Location.new(pos, chu)
