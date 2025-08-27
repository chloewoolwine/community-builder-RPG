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

# NOT NECCESARILY ORDERED
func get_neighbor_matrix() -> Array[Location]:
	var arr : Array[Location]
	for x in range(-1, 2):
		for y in range(-1, 2):
			if !(x == 0 && y == 0):
				arr.append(get_location(Vector2i(x,y)))
	return arr

func get_world_coordinates(chunk_size: int = Constants.CHUNK_SIZE) -> Vector2i:
	return (chunk * chunk_size) + position

static func get_location_from_world(world_loc: Vector2i, chunk_size:int = Constants.CHUNK_SIZE) -> Location:
	var chunk_pos: Vector2i = world_loc / chunk_size
	var square_pos: Vector2i = world_loc % chunk_size
	#print("raw square_pos: ", square_pos)
	if square_pos.x < 0:
		chunk_pos.x = chunk_pos.x - 1
		square_pos.x = chunk_size + square_pos.x
	if square_pos.y < 0:
		chunk_pos.y = chunk_pos.y - 1
		square_pos.y = chunk_size + square_pos.y
	return Location.new(square_pos, chunk_pos)

func _to_string() -> String:
	return str("Location(", position, ",", chunk, ")")
