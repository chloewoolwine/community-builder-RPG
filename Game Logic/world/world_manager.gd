extends Node2D
class_name WorldManager

@export var _world_data: WorldData
@export var world_edit_mode: bool = false
@export var load_chunks: bool = false
@export var unload_chunks: bool = false
@onready var trh: TerrainRulesHandler = $TerrainRulesHandler

var player: Player

func _ready() -> void:
	if(_world_data != null):
		set_world_data(_world_data)

func _process(_delta: float) -> void:
	## TODO... do this maybe 1/10 frames or smthn
	if _world_data and Engine.get_process_frames() % 10 == 0:
		var pos: Vector2
		if world_edit_mode:
			pos = $"../Camera2D".get_global_position()
			#load_all_chunks()
		elif player and load_chunks:
			pos = player.get_global_position()
		if Engine.get_process_frames() % 60 == 0: # Once a second might *still* be too much
			trh.run_shader_data_stuff(get_chunks_around_point(pos, 1))
		load_and_unload_chunks_surronding_point(pos)
	
func set_world_data(new_world: WorldData) -> void:
	#print("world data recieved, new world seed: ", new_world.world_seed, " \n chunks to unload: ", loaded_chunks.keys(), " \n number of new chunks: ", new_world.chunk_datas.size())
	trh.unload_all_chunks()
	while(trh.loaded_chunks.size() > 0):
		pass #this is silly but idk how else to do it and i dont feel like looking it up
	#print("new world chunk datas: ", new_world.chunk_datas)
	_world_data = new_world
	
func load_all_chunks() -> void:
	if load_chunks:
		trh.populate_set_of_chunks(_world_data.chunk_datas)
	
func load_and_unload_chunks_surronding_point(point: Vector2) -> void:
	var surronding_chunks:Array[Vector2i] = get_chunks_around_point(point, 2)
	for chunk:Vector2i in trh.loaded_chunks:
		if unload_chunks && !surronding_chunks.has(chunk):
			#print("unload chunk ", chunk)
			trh.unload_chunk(chunk, trh.loaded_chunks[chunk])
			return
	for chunk:Vector2i in surronding_chunks:
		if load_chunks && !trh.loaded_chunks.has(chunk) && _world_data.chunk_datas.has(chunk) && !trh.chunks_in_loading.has(chunk):
			#print("load chunk ", chunk)
			trh.load_chunk(chunk, _world_data.chunk_datas[chunk])
			return

func get_chunks_around_point(pos: Vector2, dist:int, debug: bool = false) -> Array[Vector2i]:
	var tileset_pos:Vector2i = trh.get_tileset_pos_from_global(pos, 0)
	var player_chunk:Vector2i = tileset_pos/_world_data.chunk_size
	if debug:
		print("tileset_pos ", tileset_pos)
		print("player_curr_chunk = ", player_chunk)
	if tileset_pos.x <= 0:
		player_chunk.x -= 1
	if tileset_pos.y <= 0:
		player_chunk.y -= 1
	
	var arr: Array[Vector2i]
	for x in range(dist * -1, dist+1):
		for y in range(dist * -1, dist+1):
			arr.append(player_chunk + Vector2i(x, y))
	if debug:
		print("player chunk = ", player_chunk)
		print("chunks: ", arr)
	return arr
	
## Callback function to send layer [int] to the function [callback]
func give_requested_layer(layer:int, callback: Callable) -> void:
	#print("requested layer: ", layer)
	#print("callback func: ", callback.get_method())
	if layer < 0:
		callback.call(trh.elevations[0])
	elif layer > trh.elevations.size():
		callback.call(trh.elevations[trh.elevations.size()-1])
	else: 
		callback.call(trh.elevations[layer])

func place_object(pos: Vector2, layer:ElevationLayer, itemdata: ItemData)->void:
	var arr: Array[Vector2i] = convert_to_chunks_at_world_pos(pos)
	var split := itemdata.object_id.split("_")
	if split[0] == "build" and split[1] == "roof":
		if !roof_cache.is_empty():
			for square in roof_cache:
				_assign_object_data(itemdata.object_id, square.position, square.chunk, layer)
			# tell all the walls they have a roof, and check to make sure they really do have it 
			var wall_data := trh.get_objects_at(arr[0], arr[1])[1]
			var all_walls := find_all_connected_walls(trh.object_atlas.live_objects[wall_data])
			for wall in all_walls:
				wall.has_decor = true
				var objects := trh.get_objects_at(wall.object_data.position, wall.object_data.chunk)
				if objects[2] == null:
					_assign_object_data(itemdata.object_id, wall.object_data.position, wall.object_data.chunk, layer)
		return
	else:
		_assign_object_data(itemdata.object_id, arr[0], arr[1], layer)

func _assign_object_data(id: String, pos: Vector2i, chunk: Vector2i, layer:ElevationLayer) -> void:
	var object_data := ObjectData.new()
	var actual_pos := ((pos * 64) + (chunk * 64 * 32)) + Vector2i(layer.elevation*-32, layer.elevation*-32) + Vector2i(32, 32)
	object_data.object_id = id
	object_data.position = pos
	object_data.chunk = chunk
	# remove later lol: 
	if id.contains("poplar"):
		object_data.object_tags["age"] = 1440000
	trh.object_atlas.place_object(object_data, actual_pos, layer.elevation)

func check_placement_validity(ind: Indicator, player_spot:Vector2, player_layer: ElevationLayer, item: ItemData) -> bool:
	if ind.global_position.distance_to(player_spot) > 400:
		ind.valid_place = false
		return false
	if player_layer != trh.get_topmost_layer_at_global_pos(ind.global_position):
		ind.valid_place = false
		return false
		
	var split := item.object_id.split("_")
	var arr: Array[Vector2i] = convert_to_chunks_at_world_pos(ind.global_position)
	if split[0] == "build":
		ind.valid_place = _build_object_placement_validity(item, split[1], arr[0], arr[1])
		return ind.valid_place 
	# TODO: other item types (plants, nature, crafted)
	
	#TODO: check tile type (no water!)
	#TODO: check overlapping positions
	ind.valid_place = true
	return ind.valid_place
	
func _build_object_placement_validity(_item: ItemData, cat: String, pos: Vector2i, chunk:Vector2i) -> bool:
	match cat:
		"wall":
			var objects := trh.get_objects_at(pos, chunk)
			if objects == [] || objects == [null, null, null, null]:
				return true
			if objects[1] == null && objects[2] == null && objects[3] == null:
				return true
		"roof":
			var objects := trh.get_objects_at(pos, chunk)
			if objects == [] || objects == [null, null, null, null]:
				return false
			if objects[1] != null:
				var split := objects[1].object_id.split("_")
				if split[0] == "build" && split[1] == "wall":
					var to_roof := _find_roofs(trh.object_atlas.live_objects[objects[1]])
					#TODO! ROOF _find_roof() has an array called all_found. put roofs on those squares !
					if to_roof.size() > 0:
						roof_cache = to_roof
						return true
	return false

var roof_cache: Array[Location]

func find_all_connected_walls(wall: GenericWall) -> Array[GenericWall]:
	var next: Array[GenericWall] = [wall]
	var x : int = 0 
	#print("finding all walls...")
	while x < next.size():
		#print("next size: ", next.size())
		var curr := next[x]
		#print("adding curr ", curr, " to visited")
		var neighbors := curr.neighbors
		for neighbor in neighbors:
			if neighbor != null and neighbor not in next:
				#print("adding to next ", neighbor.position)
				next.append(neighbor)
		x = x + 1
	return next

#TODO: call is_valid for all 4 square adjactent to what the player clicked on
#if valid, fill (which should be the same algorithm but actually places it 
#if any walls are left unfilled, call _is_valid on each of them 	
func _find_roofs(wall: GenericWall) -> Array[Location]:
	var all_found: Array[Location] = []
	var valid := _is_valid(wall.object_data.position + Vector2i(0, -1), wall.object_data.chunk, all_found, 0)
#	print("all found: ", all_found)
	print("all found: ", all_found.size())
	print("valid: ", valid)
	if all_found.size() > 3 and valid: 
		return all_found
	return []
	
func _is_valid(pos: Vector2i, chunk:Vector2i, all_found: Array[Location], dist: int) -> bool:
	if chunk not in trh.loaded_chunks.keys():
		return false
	var square := trh.get_square_at(pos, chunk)
	if square.object_data && square.object_data[2] != null or dist > 32:
		#print("Faaaalseeee")
		return false
	var loc := Location.new(pos, chunk)
	for f in all_found:
		if loc.equals(f):
			return true
	all_found.append(loc)
	if square.object_data && square.object_data[1] && square.object_data[1].object_id.contains("wall"): 
		#print(square.object_data[1].object_id)
		return true
	dist = dist + 1
	var arrleft := trh.get_neighbor_square(pos, chunk, Vector2i(-1, 0))
	var arrright := trh.get_neighbor_square(pos, chunk, Vector2i(1, 0))
	var arrup := trh.get_neighbor_square(pos, chunk, Vector2i(0, -1))
	var arrdown := trh.get_neighbor_square(pos, chunk, Vector2i(0, 1))
	var left := _is_valid(arrleft[0], arrleft[1], all_found, dist)
	dist = dist
	var right := _is_valid(arrright[0], arrright[1], all_found, dist)
	dist = dist
	var up := _is_valid(arrup[0], arrup[1], all_found, dist)
	dist = dist
	var down := _is_valid(arrdown[0], arrdown[1], all_found, dist)
	dist = dist
	return left and right and up and down

## this is HELLA innefficient but n will not be > than 32x32ish... so..
func _dfs(curr: GenericWall, path: Array[GenericWall]) -> Array[GenericWall]:
	if path.size() > 0 && curr == path[0]: 
		return path
	path.append(curr)
	
	var biggest: Array[GenericWall] = path
	for neighbor in curr.neighbors:
		if neighbor != null and neighbor not in path:
			var new_array : Array[GenericWall] = []
			new_array.append_array(path)
			var n_path := _dfs(neighbor, new_array)
			if n_path.size() > biggest.size():
				biggest = n_path
	
	return biggest

# Returns true if the modification is successful
# this probably isnt the best way to do this
func modify_tilemap(loc: Vector2, layer: ElevationLayer, action: String) -> bool:
	#print("global: ", loc)
	if layer == null:
		#print("modification failed, layer was null at global: ", loc) 
		return false
	if layer != trh.get_topmost_layer_at_global_pos(loc):
		return false
	var positions:Array[Vector2i] = convert_to_chunks_at_world_pos(loc)
	
	if action == "water":
		trh.water_square_at(positions[0], positions[1])
	if action == "till": 
		trh.apply_floor_at(positions[0], positions[1], action)
	if action == "remove_floor":
		trh.remove_floor_at(positions[0], positions[1])
	return true
	
## Returns [square_pos, chunk_pos]. loc MUST be a global position (like from a transform)
func convert_to_chunks_at_world_pos(loc: Vector2) -> Array[Vector2i]:
	var arr :Array[Vector2i] = []
	var layer := trh.get_topmost_layer_at_global_pos(loc)
	if layer == null:
		return arr
	var local: Vector2i = layer.local_to_map(layer.to_local(loc))
	var chunk_pos: Vector2i = local / _world_data.chunk_size
	var square_pos: Vector2i = local % _world_data.chunk_size
	#print("raw square_pos: ", square_pos)
	if square_pos.x < 0:
		chunk_pos.x = chunk_pos.x - 1
		square_pos.x = _world_data.chunk_size.x + square_pos.x
	if square_pos.y < 0:
		chunk_pos.y = chunk_pos.y - 1
		square_pos.y = _world_data.chunk_size.y + square_pos.y
	#print("chunk position: ", chunk_pos)
	#print("corrected square: ", square_pos)
	arr.append_array([square_pos, chunk_pos])
	return arr
	
# Shaders can take indicators job: 
# https://www.youtube.com/watch?v=7nTQA_6CL6M
func move_indicator(indicator: Indicator, player_spot: Vector2, item: ItemData)-> void:
	var player_layer: ElevationLayer = player.elevation_handler.current_map_layer
	var old := indicator.global_position
	indicator.global_position = player_layer.map_to_local(player_layer.local_to_map(get_global_mouse_position()))
	if indicator.global_position != old: 
		roof_cache.clear()
		check_placement_validity(indicator, player_spot, player_layer, item)

	#var left: GenericWall = walls[0]
	#var right: GenericWall = walls[0]
	#var down: GenericWall = walls[0]
	#var up: GenericWall = walls[0]
	#for wall in walls: 
		#if wall.global_position.x < left.global_position.x:
			#left = wall
		#elif wall.global_position.x > right.global_position.x:
			#right = wall
		#if wall.global_position.y < up.global_position.y: 
			#up = wall
		#elif wall.global_position.y > down.global_position.y: 
			#down = wall
	#return [left, right, down, up]
