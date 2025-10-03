extends Node2D
class_name WorldManager

signal spawn_pickups(location:Vector2, list: Array)

@export var _world_data: WorldData
@export var world_edit_mode: bool = false
@export var load_chunks: bool = false
@export var unload_chunks: bool = false
@onready var trh: TerrainRulesHandler = $TerrainRulesHandler

var player: Player

func _ready() -> void:
	if(_world_data != null):
		set_world_data(_world_data)

#called in game to initiate most set up actions
func do_setup() -> void: 
	EnvironmentLogic.run_water_calc(_world_data, get_chunks_around_point(player.get_global_position(), 2))
	if player:
		print("player")
		player.velocity_handler.try_step.connect(is_stepable_layer)
	#entity collisions afterwards

func _process(_delta: float) -> void:
	## TODO... do this maybe 1/10 frames or smthn
	if _world_data and Engine.get_process_frames() % 10 == 0:
		var pos: Vector2
		if world_edit_mode:
			pos = $"../Camera2D".get_global_position()
			#load_all_chunks()
		elif player and load_chunks:
			pos = player.get_global_position()
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
	var surronding_chunks:Array[Vector2i] = get_chunks_around_point(point, 1)
	for chunk:Vector2i in trh.loaded_chunks:
		if unload_chunks && !surronding_chunks.has(chunk):
			#print("unload chunk ", chunk)
			trh.unload_chunk(chunk, trh.loaded_chunks[chunk])
			continue
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

func manage_propagation_success(pos: Location, object_id: String) -> void: 
	pass # LOL ! TODO: properly use environment logic to place things instead of this
	#print("checking for propagation of ", object_id, " at ", pos.position)
	#var database := DatabaseManager.WORLD_DATABASE
	var _split := object_id.split("_")
	#print(_split[2])
	#if database._has_string_id(&"GenerationData", StringName(_split[2])):
		#database.fetch_data(&"GenerationData", StringName(_split[2]))
	#else:
		#print(database.fetch_collection_data(&"GenerationData").keys())
	#var plant_data:PlantGenData = database.fetch_data("GenerationData",_split[2])
	if pos.chunk in trh.loaded_chunks.keys():
		var square := trh.get_square_at(pos.position, pos.chunk)
		match square.type:
			SquareData.SquareType.Rock:
				return
			SquareData.SquareType.Sand:
				# no plants for sand. Yet
				return
			SquareData.SquareType.Grass:
				pass
			SquareData.SquareType.Dirt:
				pass
		var objects := trh.get_objects_at(pos.position, pos.chunk)
		if !trh.has_objects(square) || (objects.size() > 1 && objects[0] == null and objects[1] == null):
			_assign_object_data(object_id, pos.position, pos.chunk, trh.elevations[square.elevation])
		#TODO: check for closeby trees
	else:
		#plants could technically try to propagate to an unloaded chunk- 
		#this should be theoretically fine, but im not doing that rn fuck that honestly
		#TODO: plants should propagate in unloaded chunks
		pass

func place_object(pos: Vector2, _player_pos:Vector2, itemdata: ItemData)->void:
	var arr: Array[Vector2i] = convert_to_chunks_at_world_pos(pos)
	var layer: ElevationLayer = trh.get_elevation_at(_world_data.chunk_datas[arr[1]].square_datas[arr[0]].elevation)
	var split := itemdata.object_id.split("_")
	#_place_build_object calls _assign_object_data - it just needs a lot of extra 
	# in case of wall or roof 
	print("placing ", split)
	if split[0] == "build":
		_place_build_object(arr, split, layer, itemdata)
	else:
		_assign_object_data(itemdata.object_id, arr[0], arr[1], layer)

#spagethhi extrodinare. TODO: clean this up please
func _place_build_object(arr: Array[Vector2i], split: Array[String], layer: ElevationLayer, itemdata:ItemData) -> void: 
	if split[1] == "roof":
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
	elif split[1] == "door":
		var wall_data := trh.get_objects_at(arr[0], arr[1])[1]
		var live_wall:GenericWall = trh.object_atlas.live_objects[wall_data]
		live_wall.is_door = true
		live_wall.remove_my_decor.connect(peel_wall)
		wall_data.object_tags["door"] = split[2]
		_assign_object_data(itemdata.object_id, wall_data.position, wall_data.chunk, layer)
	elif split[1] == "wall":
		_assign_object_data(itemdata.object_id, arr[0], arr[1], layer)
	elif split[1] == "terrain": #its dirt baby
		if split[2] == "dirt":
			raise_elevation(Location.new(arr[0], arr[1]), SquareData.SquareType.Dirt)

func _assign_object_data(id: String, pos: Vector2i, chunk: Vector2i, _layer:ElevationLayer) -> void:
	var obj := EnvironmentLogic.place_object_data(_world_data, Location.new(pos, chunk), StringName(id))
	if obj == null:
		push_warning("EnvironmentLogic couldn't place object ", id, " at pos: ", pos, " chunk: ", chunk)
		return #not a valid place
	var actual_pos := EnvironmentLogic.get_real_pos_object(Location.new(pos, chunk), _layer.elevation)
	trh.object_atlas.place_object(obj, actual_pos, trh.get_square_at(pos, chunk))

func raise_elevation(loc: Location, type: SquareData.SquareType) -> void:
	var square := EnvironmentLogic.get_square(_world_data, loc)
	square.type = type
	square.elevation = square.elevation + 1 
	trh.raise_elevation(loc)

func check_placement_validity(ind: Indicator, player_spot:Vector2, player_layer: ElevationLayer, item: ItemData) -> bool:
	if ind.global_position.distance_to(player_spot) > 400:
		ind.valid_place = false
		return false
	if player_layer.elevation != trh.request_square_at_loc(ind.current_spot).elevation:
		ind.valid_place = false
		return false
		
	var split := item.object_id.split("_")
	#print("indicator current spot: ", ind.current_spot)
	
	if split[0] == "build":
		ind.valid_place = _build_object_placement_validity(item, split[1], ind.current_spot.position,ind.current_spot.chunk)
		return ind.valid_place 
	if split[0] == "plant":
		ind.valid_place = _plant_object_placement_validity(item, split[1], ind.current_spot.position, ind.current_spot.chunk)
		return ind.valid_place
	# TODO: other item types (plants, nature, crafted)
	
	#TODO: check tile type (no water!)
	#TODO: check overlapping positions
	ind.valid_place = true
	return ind.valid_place
	
func _plant_object_placement_validity(_item: ItemData, _cat: String, pos: Vector2i, chunk:Vector2i) -> bool:
	var square := trh.get_square_at(pos, chunk)
	var _objects := trh.get_objects_at(pos, chunk)
	#TODO: this is where beans, squash, and corn would cuddle
	# and where vines would crawl on walls n stuff
	if trh.has_objects(square):
		return false
	match square.type:
		SquareData.SquareType.Rock:
			return false
		SquareData.SquareType.Sand:
			# no plants for sand. Yet
			return false
		SquareData.SquareType.Grass:
			pass
		SquareData.SquareType.Dirt:
			pass
	
	return true

#TODO: i reaaaallly gotta set up some kind of "rule" system or wholesale steal it from that plugin i bought
#need "rules" for validity, like tile type, whether or not it has objects, whether it has floors, etc.
#then, need "rules" for actual placement- what actually happens when object is placed
func _build_object_placement_validity(_item: ItemData, cat: String, pos: Vector2i, chunk:Vector2i) -> bool:
	match cat:
		"wall":
			var objects := trh.get_objects_at(pos, chunk)
			if objects == [] || objects == [null, null, null]:
				return true
			if objects[1] == null && objects[2] == null:
				return true
		"roof":
			var objects := trh.get_objects_at(pos, chunk)
			if !trh.has_objects(trh.get_square_at(pos, chunk)):
				return false
			if objects[1] != null:
				@warning_ignore("untyped_declaration")
				var object = trh.object_atlas.live_objects[objects[1]]
				if object is GenericWall:
					var to_roof := _find_roofs(object)
					#TODO! ROOF _find_roof() has an array called all_found. put roofs on those squares !
					if to_roof.size() > 0:
						roof_cache = to_roof
						return true
		"door": 
			print("door")
			var objects := trh.get_objects_at(pos, chunk)
			if objects == [] || objects.size() < 2: 
				return false
			if objects[1] != null:
				@warning_ignore("untyped_declaration")
				var object = trh.object_atlas.live_objects[objects[1]]
				if object is GenericWall:
					print(object.neighbors)
					if object.neighbors[1] != null and object.neighbors[3] != null and object.neighbors[0] == null and object.neighbors[2] == null:
						print("has the right friends")
						return !object.neighbors[1].is_door and !object.neighbors[3].is_door and !object.has_decor and !object.is_window and !object.is_door
		"terrain":
			var square:SquareData = trh.get_square_at(pos, chunk)
			if square.elevation < 3 && !trh.has_objects(square):
				#print("terrain")
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

func peel_wall(_wall: GenericWall) -> void:
	var wall_data := _wall.object_data
	trh.remove_decor_at(wall_data.position, wall_data.chunk)

func destroy_object(object: ObjectData) -> void:
	trh.remove_object_at(object.position, object.chunk)
	
func destroy_roof(object: ObjectData) -> void: 
	#TODO: this
	trh.remove_roof_at(object.position, object.chunk)
	pass

func modify_terrain(loc: Vector2, to_tile: SquareData.SquareType) -> void:
	#this should only be used for the map editor - terrain modification will prolly be different
	var pos := convert_to_chunks_at_world_pos(loc)
	if pos.size() > 1:
		trh.change_type_to(pos[0], pos[1], to_tile)

func change_water(loc: Vector2, new_water: int) -> void:
	if new_water < 0:
		new_water = 0
	if new_water > 5: 
		new_water = 5
	var pos := convert_to_chunks_at_world_pos(loc)
	print(pos)
	if pos.size() > 1:
		trh.change_water(pos[0], pos[1], new_water)

#TODO: this solution sucks dookie!
const DIRT :ItemData = preload("uid://dtsowgtv4r3xb")
# Returns true if the modification is successful
# this probably isnt the best way to do this
func modify_tilemap(loc: Location, _origin_pos: Vector2, action: String) -> bool:
	var layer: ElevationLayer = trh.get_elevation_at(_world_data.chunk_datas[loc.chunk].square_datas[loc.position].elevation)
	print("global: ", loc)
	if layer == null:
		print("modification failed, layer was null at global: ", loc) 
	
	if action == "water":
		trh.water_square_at(loc)
	if action == "till": 
		trh.apply_floor_at(loc, action)
	if action == "shovel":
		var square := EnvironmentLogic.get_square(_world_data, loc)
		if EnvironmentLogic.has_objects(square) || square.type == SquareData.SquareType.Grass:
			## TODO: more granular logic for removing objects
			trh.remove_floor_at(loc)
		else:
			if square.elevation > 0 && square.type == SquareData.SquareType.Dirt:
				square.elevation = square.elevation - 1 
				trh.lower_elevation(loc)
				var dirt_array: Array[ItemData]
				dirt_array.append(DIRT)
				spawn_pickups.emit(get_global_mouse_position(), dirt_array)
			else:
				return false
	return true

func get_objects_at_world_pos(loc: Vector2) -> Array[ObjectData]:
	var layer := trh.get_topmost_layer_at_global_pos(loc)
	if layer == null:
		return []
	var local := convert_to_chunks_at_world_pos(loc)
	return trh.get_objects_at(local[0], local[1])

## Returns [square_pos, chunk_pos]. loc MUST be a global position (like from a transform)
func convert_to_chunks_at_world_pos(loc: Vector2) -> Array[Vector2i]:
	var arr :Array[Vector2i] = []
	var layer := trh.get_topmost_layer_at_global_pos(loc)
	if layer == null:
		return arr
	var local: Vector2i = layer.local_to_map(layer.to_local(loc))
	#print("raw local: ", local)
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
	
func move_indicator(indicator: Indicator, player_spot: Vector2, item: ItemData)-> void:
	var mouse := get_global_mouse_position()
	var loc := convert_to_chunks_at_world_pos(mouse)
	var square_data:SquareData = trh.request_square_at(loc[0], loc[1])
	if square_data == null:
		return
	var mouse_layer := trh.elevations[square_data.elevation]
	var old := indicator.global_position
	indicator.current_spot = Location.new(loc[0], loc[1])
	indicator.global_position = mouse_layer.to_global(mouse_layer.map_to_local(mouse_layer.local_to_map(mouse_layer.to_local(mouse))))
	if indicator.global_position != old: 
		roof_cache.clear()
		check_placement_validity(indicator, player_spot, mouse_layer, item)

func water_timer(day:int, hour:int, minute:int) -> void:
	if hour == 3 && minute == 0:
		EnvironmentLogic.run_daily(_world_data, day, hour, minute)
	if minute == 30:
		#TODO: make this async some how 
		EnvironmentLogic.run_water_calc(_world_data, get_chunks_around_point(player.get_global_position(), 2))

func is_stepable_layer(handler: VelocityHandler, to_layer: ElevationLayer, callback: Callable) -> void:
	var loc := convert_to_chunks_at_world_pos(handler.global_position)
	var square_data:SquareData = trh.request_square_at(loc[0], loc[1])
	if abs(square_data.elevation - to_layer.elevation) == 1:
		#going up 
		callback.call(true)
	if square_data.elevation == to_layer.elevation:
		var other_loc := Location.new(loc[0], loc[1]).get_location(handler.curr_dirr.normalized().snapped(Vector2.ONE))
		var other_square:SquareData = trh.request_square_at(other_loc.position, other_loc.chunk)
		if abs(square_data.elevation - other_square.elevation) == 1:
			#going down
			callback.call(false)
		#TODO: check for water and then all the swimming stuff 
		pass
