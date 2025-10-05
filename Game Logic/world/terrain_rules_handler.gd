extends Node2D
class_name TerrainRulesHandler

const ELEVATION_LAYER = preload("res://Scenes/world/elevation_layer.tscn")
@export var debug: bool = false
@export var elevations: Array[ElevationLayer]
@onready var object_atlas: ObjectAtlas = $ObjectAtlas
@onready var bbc: BackBufferCopy = $BackBufferCopy

## TODO: attatch the entity/object loading to this method
signal chunk_loaded(chunk: ChunkData)
signal chunk_unloaded(chunk: ChunkData)

##TODO:
## after/before/whenever loading the chunk, we need to compute a gradient
## of the Moisture, and send that gradient to the shader so it can apply
## special colors. 1->2->3->4 need to be Obvious. Also, we need to make 
## a seperate texture for each elevation (in order to get the offset correct)
## and have it actually match what its supposed too
var loaded_chunks: Dictionary
## Map of chunk pos to what needs to be loaded
var chunks_in_loading: Dictionary
## Map of chunk pos to next row
var chunk_row_next: Dictionary
var chunks_to_unload: Dictionary

func _ready() -> void:
	for child in bbc.get_children():
		if child is ElevationLayer and !elevations.has(child):
			elevations.append(child)
	for z in elevations.size():
		elevations[z].elevation = z
		elevations[z].position.y = EnvironmentLogic.ele_y_offset(z)
	object_atlas.new_object_placed.connect(add_object)

func _process(_delta: float) -> void:
	## load chunk proccess
	if chunks_in_loading.keys().size() > 0:
		var key: Vector2i = chunks_in_loading.keys()[0]
		#print("loading key: ", key)
		if !chunk_row_next.has(key):
			chunk_row_next[key] = 0 
		var next_row:int = chunk_row_next.get(key)
		var chunk_data:ChunkData = chunks_in_loading.get(key)
		if next_row >= chunk_data.chunk_size.x:
			## Done! 
			chunks_in_loading.erase(key)
			chunk_row_next.erase(key)
			loaded_chunks[key] = chunk_data
			chunk_loaded.emit(chunk_data)
				#print("key did not erase, ", key)
			#print("chunk_row_next: ", chunk_row_next.keys())
		else:
			var chunk_pos:Vector2i = chunk_data.chunk_position * chunk_data.chunk_size
			for y in range(chunk_data.chunk_size.y):
				var square:SquareData = chunk_data.square_datas[Vector2i(next_row,y)]
				translate_square_data_to_tile(square, chunk_pos + square.location_in_chunk, chunk_data.chunk_position)
			chunk_row_next[key] = next_row + 1
	## unload chunks proccess 
	if chunks_to_unload.keys().size() > 0:
		var key: Vector2i = chunks_to_unload.keys()[0]
		#print("unloading key: " , key)
		if chunks_in_loading.has(key): 
			chunks_in_loading.erase(key)
			chunk_row_next.erase(key)
		if !chunk_row_next.has(key):
			chunk_row_next[key] = 0 
		var next_row:int = chunk_row_next.get(key)
		var chunk_data:ChunkData = chunks_to_unload.get(key)
		if next_row >= chunk_data.chunk_size.x:
			## Done! 
			chunks_to_unload.erase(key)
			chunk_row_next.erase(key)
			loaded_chunks.erase(key)
			chunk_unloaded.emit(chunk_data)
		else:
			var chunk_pos:Vector2i = chunk_data.chunk_position * chunk_data.chunk_size
			for y in range(chunk_data.chunk_size.y):
				var square:SquareData = chunk_data.square_datas[Vector2i(next_row,y)]
				for ele in elevations:
					ele.delete_square(chunk_pos + square.location_in_chunk)
					# removes objects from scene + updates their state if dead
				square.object_data = object_atlas.remove_objects(square.object_data, Location.new(square.location_in_chunk, chunk_data.chunk_position))
			chunk_row_next[key] = next_row + 1
		
	#print("chunks in loading: ", chunks_in_loading.keys())
	#print("chunks to unload: ", chunks_to_unload.keys())
	#print("chunks loaded: ", loaded_chunks.keys())

func get_tileset_pos_from_global(pos: Vector2, layer: int) -> Vector2i: 
	return elevations[layer].local_to_map(pos)
	
## Gets the highest layer at INGAME COORDINATE [pos]
func get_topmost_layer_at_ingame_pos(pos: Vector2i) -> ElevationLayer:
	@warning_ignore("unused_variable")
	var highest := 0
	for x in range(1, elevations.size()):
		var add:int = 0
		@warning_ignore("integer_division")
		if x % 2 != 0 && int(pos.y) / 64 < 32:
			add = 1
		@warning_ignore("integer_division")
		var loc := Location.get_location_from_world(pos + (Vector2i(0,1) * ((x+add)/2)))
		if loc.chunk not in loaded_chunks:
			continue
		var square:SquareData = loaded_chunks[loc.chunk].square_datas[loc.position]
		if square.elevation != x:
			continue
		highest = x
	return elevations[highest]

func get_topmost_layer_at_global_pos(pos: Vector2) -> ElevationLayer:
	# tilespace calculation: z * -32 = y
	# 1. find all possible active tileset positions
	# 2. return the highest one 
	var base_layer: Vector2i = elevations[0].local_to_map(elevations[0].to_local(pos))
	var highest := 0
	for x in range(1, elevations.size()):
		var add:int = 0
		@warning_ignore("integer_division")
		if x % 2 != 0 && abs(int(pos.y) % 64) < 32:
			add = 1
		@warning_ignore("integer_division")
		var loc := Location.get_location_from_world(base_layer + (Vector2i(0,1) * ((x+add)/2)))
		if loc.chunk not in loaded_chunks:
			continue
		var square:SquareData = loaded_chunks[loc.chunk].square_datas[loc.position]
		if square.elevation != x:
			continue
		highest = x
	return elevations[highest]

func unload_all_chunks() -> void:
	unload_set_of_chunks(loaded_chunks)
	
func load_chunk(pos: Vector2i, chunk: ChunkData) -> void:
	if(!chunks_in_loading.has(pos)):
		chunks_in_loading[pos] = chunk

func unload_chunk(pos: Vector2i, chunk: ChunkData) -> void:
	if(!chunks_to_unload.has(pos)):
		chunks_to_unload[pos] = chunk
		
func unload_set_of_chunks(chunks: Dictionary) -> void:
	chunks_to_unload.merge(chunks) ## THIS might break???
		
func populate_set_of_chunks(chunks: Dictionary) -> void:
	chunks_in_loading.merge(chunks)
	
func translate_square_data_to_tile(data: SquareData, world_pos: Vector2i, _chunk_overall: Vector2i)-> void:
	var ele:int = data.elevation
	#print("loading tile: ", world_pos, " elevation: ", ele)
	if (ele >= elevations.size()):
		for x in range(elevations.size(), ele+1):
			#print_if_debug(str("creating new layer: ", x))
			var new_layer:ElevationLayer = ELEVATION_LAYER.instantiate()
			new_layer.name = str("Elevation",x)
			new_layer.elevation = x
			bbc.add_child(new_layer)
			#print_if_debug(str(new_layer.get_children()))
			elevations.append(new_layer)
			elevations[x].elevation = x
			elevations[x].position.y = EnvironmentLogic.ele_y_offset(x)
			
	for x in range(0, data.elevation):
		#print("building base in elevation: ", x)
		elevations[x].build_base_of(data, world_pos)
	elevations[ele].set_square(data, world_pos)
	if data.object_data != null:
		var actual_pos := EnvironmentLogic.get_real_pos_object(Location.get_location_from_world(world_pos), data.elevation)
		#anyhow, the world data should be the ultimate authority for an objects position
		for object in data.object_data:
			if object != null:
				object.position = data.location_in_chunk
				object.chunk = _chunk_overall
		object_atlas.translate_object(data.object_data, actual_pos, data)
		_settle_objects_at_square(data)
	
func remove_floor_at(pos: Location) -> void:
	var chunk_data:ChunkData = loaded_chunks[pos.chunk]
	if chunk_data == null:
		print("warning! tried to remove floor at unloaded chunk: ", pos.chunk, " square: ", pos.position)
		return
	var square: SquareData = chunk_data.square_datas[pos.position]
	var overall_pos := (pos.chunk * chunk_data.chunk_size) + pos.position
	if square.object_data && square.object_data[0]:
		square.object_data[0] = null
		# TODO: different floor types will probably have other layers? 
		elevations[square.elevation].remove_till(overall_pos)
		return
	if square.type == SquareData.SquareType.Grass:
		square.type = SquareData.SquareType.Dirt
		elevations[square.elevation].remove_grass(overall_pos)
		return 

## Runtime method for applying floors 
func apply_floor_at(pos: Location, floor_type: String) -> void: 
	var chunk_data:ChunkData = loaded_chunks[pos.chunk]
	if chunk_data == null:
		print("warning! tried to aplly floor at unloaded chunk: ", pos.chunk, " square: ", pos.position)
		return
	var square: SquareData = chunk_data.square_datas[pos.position]
	if floor_type == "till": 
		## no objects, apply immediately 
		if square_has_no_objects(square) && square.water_saturation < 4:
			var overall_pos := (pos.chunk * chunk_data.chunk_size) + pos.position
			match square.type:
				SquareData.SquareType.Dirt:
					var new_floor: FloorData = FloorData.new()
					new_floor.object_id = "till"
					if square.object_data == null || square.object_data.is_empty():
						square.object_data = [null, null, null]
					square.object_data[0] = new_floor
					elevations[square.elevation].till_square(overall_pos, square)
				SquareData.SquareType.Sand:
					pass # idk what to do here yet
				SquareData.SquareType.Grass:
					square.type = SquareData.SquareType.Dirt
					elevations[square.elevation].remove_grass(overall_pos)
				SquareData.SquareType.Rock:
					pass # do absolutely nothing
		else: 
			# TODO: pop the object off 
			pass
			
func square_has_no_objects(square: SquareData) -> bool:
	print("square object data: ", square.object_data)
	print("square: ", square.location_in_chunk)
	if square.object_data == null || square.object_data.is_empty(): 
		return true
	for x in square.object_data:
		if x != null:
			return false
	return true

## Runtime method for watering
func water_square_at(pos: Location) -> void:
	var chunk_data:ChunkData = loaded_chunks[pos.chunk]
	if chunk_data == null:
		print("warning! tried to water at unloaded chunk: ", pos.chunk, " square: ", pos.position)
		return
	#print("square_pos: ", square_pos)
	var square: SquareData = chunk_data.square_datas[pos.position]
	if square.water_saturation < 3:
		#print("old water: ", square.water_saturation)
		square.water_saturation += 1
		#print("new water: ", square.water_saturation)
		elevations[square.elevation].update_specific_pixel(pos.get_world_coordinates(), square)

func remove_roof_at(square_pos: Vector2i, chunk_pos: Vector2i) -> void:
	var chunk: ChunkData = loaded_chunks[chunk_pos]
	var square: SquareData = chunk.square_datas[square_pos]
	if square.object_data.size() > 2:
		object_atlas.pop_away_object(square.object_data[2])
		square.object_data[2] = null
	_settle_objects_at_square(square)

func remove_object_at(square_pos: Vector2i, chunk_pos: Vector2i) -> void:
	var chunk: ChunkData = loaded_chunks[chunk_pos]
	var square: SquareData = chunk.square_datas[square_pos]
	if square.object_data.size() > 1:
		object_atlas.pop_away_object(square.object_data[1])
		square.object_data[1] = null
	_settle_objects_at_square(square)
		
func remove_decor_at(square_pos: Vector2i, chunk_pos: Vector2i) -> void:
	var chunk: ChunkData = loaded_chunks[chunk_pos]
	var square: SquareData = chunk.square_datas[square_pos]
	for x in range(3, square.object_data.size()):
		object_atlas.pop_away_object(square.object_data[x])
		square.object_data[x] = null
	_settle_objects_at_square(square)

# world manager parses request -> object atlas (adds it) -- signals to --> trh to keep track of data
func add_object(object_data: ObjectData) -> void: 
	var chunk: ChunkData = loaded_chunks[object_data.chunk]
	var square: SquareData = chunk.square_datas[object_data.position]
	if !has_objects(square):
		if !has_floor(square):
			square.object_data = [null, null, null]
		else: 
			square.object_data = [square.object_data[0], null, null]
	if object_data.object_id.contains("roof"):
		square.object_data[2] = object_data
	elif object_data.additive:
		square.object_data.append(object_data)
	else: 
		square.object_data[1] = object_data
	_settle_objects_at_square(square)

func _settle_objects_at_square(square: SquareData) -> void: 
	if square.object_data == null: # i dont think this is possible, but you never know
		square.object_data = []
		return
	if square.object_data.is_empty():
		return
	var all_null: bool = true
	for x in square.object_data:
		if x != null:
			all_null = false
	if all_null:
		square.object_data = []
		return
	
	#objects are not empty: settle the decor correctly
	#first grab roof, base, and floor
	var size := square.object_data.size()
	var new_objects : Array[ObjectData]
	# this feels stupid, but i programmed it kind of stupid so 
	for i in range(0, 3):
		if size > i:
			new_objects.append(square.object_data[i])
		else:
			new_objects.append(null)
	if size > 3:
		for i in range(3, square.object_data.size()):
			#clear any nulls in the decor
			if square.object_data[i] != null:
				new_objects.append(square.object_data[i])
	square.object_data = new_objects

func get_objects_at(square: Vector2i, chunk: Vector2i) -> Array[ObjectData]: 
	if chunk in loaded_chunks:
		return loaded_chunks[chunk].square_datas[square].object_data
	return []

func change_type_to(square: Vector2i, chunk: Vector2i, to: SquareData.SquareType) -> void:
	var chunk_data:ChunkData = loaded_chunks[chunk]
	var square_data: SquareData = chunk_data.square_datas[square]
	square_data.type = to
	var chunk_pos:Vector2i = chunk * chunk_data.chunk_size
	elevations[square_data.elevation].change_square(square_data, chunk_pos + square)

func change_water(square: Vector2i, chunk: Vector2i, new_water: int) -> void: 
	var chunk_data:ChunkData = loaded_chunks[chunk]
	var square_data: SquareData = chunk_data.square_datas[square]
	square_data.water_saturation = new_water
	var chunk_pos:Vector2i = chunk * chunk_data.chunk_size
	elevations[square_data.elevation].change_square(square_data, chunk_pos + square)

## Returns [square, chunk]
## don't put val > 32 in dir plz
func get_neighbor_square(square: Vector2i, chunk: Vector2i, dir: Vector2i) -> Array[Vector2i]: 
	var pos := square + dir
	var chu := chunk
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
	return [pos, chu]

func get_square_at(square: Vector2i, chunk: Vector2i) -> SquareData: 
	return loaded_chunks[chunk].square_datas[square]

func has_objects(square: SquareData) -> bool: 
	var objects := square.object_data
	if objects.size() < 1: 
		return false
	if objects.size() > 2: 
		for x in range(1, objects.size()): 
			if objects[x] != null:
				return true
	return false

func has_floor(square: SquareData) -> bool: 
	var objects := square.object_data
	if objects.size() < 1: 
		return false
	if objects[0] == null:
		return false
	return true

func print_if_debug(string: String) -> void:
	if debug:
		print(self.name, ":::", string)

func request_square_at(square: Vector2i, chunk: Vector2i) -> SquareData:
	if chunk in loaded_chunks:
		return loaded_chunks[chunk].square_datas[square]
	return null

func request_square_at_loc(loc: Location) -> SquareData:
	if loc.chunk in loaded_chunks:
		return loaded_chunks[loc.chunk].square_datas[loc.position]
	return null
	
func get_elevation_at(num: int) -> ElevationLayer:
	return elevations[num]

func lower_elevation(loc: Location) -> void:
	if !(loc.chunk in loaded_chunks):
		return
	var chunk:ChunkData = loaded_chunks[loc.chunk]
	var square:SquareData = chunk.square_datas[loc.position]
	elevations[square.elevation+1].remove_base(loc.get_world_coordinates())
	#elevations[square.elevation].change_square(square, chunk_pos + loc.position)
	#var friends := loc.get_neighbor_matrix()
	#for f in friends:
		#var chunk_data:ChunkData = loaded_chunks[f.chunk]
		#var chunk_pos_:Vector2i = chunk_data.chunk_position * chunk_data.chunk_size
		#var square_:SquareData = chunk_data.square_datas[f.position]
		##for ele in elevations:
			##ele.change_square(square, chunk_pos + square.location_in_chunk)
		#elevations[square_.elevation].change_square(square_, chunk_pos_ + f.position)

func raise_elevation(loc: Location) -> void: 
	if !(loc.chunk in loaded_chunks):
		return
	var chunk:ChunkData = loaded_chunks[loc.chunk]
	var square:SquareData = chunk.square_datas[loc.position]
	if square.elevation >= elevations.size():
		var ele:int = square.elevation
		for x in range(elevations.size(), ele+1):
			#print_if_debug(str("creating new layer: ", x))
			var new_layer:ElevationLayer = ELEVATION_LAYER.instantiate()
			new_layer.name = str("Elevation",x)
			new_layer.elevation = x
			bbc.add_child(new_layer)
			#print_if_debug(str(new_layer.get_children()))
			elevations.append(new_layer)
			elevations[x].elevation = x
			elevations[x].position.y = EnvironmentLogic.ele_y_offset(x)
	print(elevations)
	elevations[square.elevation].add_base(loc.get_world_coordinates())
