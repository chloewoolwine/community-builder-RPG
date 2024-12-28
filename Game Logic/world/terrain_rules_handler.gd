extends Node2D
class_name TerrainRulesHandler

const ELEVATION_LAYER = preload("res://Scenes/world/elevation_layer.tscn")
@export var elevations: Array[ElevationLayer]
@export var debug: bool = false
@onready var object_atlas: ObjectAtlas = $ObjectAtlas

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
	for child in get_children():
		if child is ElevationLayer and !elevations.has(child):
			elevations.append(child)
	for x in elevations.size():
		elevations[x].elevation = x
		elevations[x].position.y = x * -32

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
				translate_square_data_to_tile(square, chunk_pos + square.location_in_chunk)
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
					square.object_datas = object_atlas.remove_objects(square.object_datas)
			chunk_row_next[key] = next_row + 1
		
	#print("chunks in loading: ", chunks_in_loading.keys())
	#print("chunks to unload: ", chunks_to_unload.keys())
	#print("chunks loaded: ", loaded_chunks.keys())

func get_tileset_pos_from_global(pos: Vector2) -> Vector2i: 
	return elevations[0].local_to_map(pos)
	
## Gets the highest layer at INGAME COORDINATE [pos]
func get_topmost_layer_at_ingame_pos(pos: Vector2i) -> ElevationLayer:
	elevations.reverse()
	for layer in elevations:
		if layer.get_cell_source_id(pos) != -1:
			elevations.reverse()
			return layer
	#push_error("Error: couldn't find any tiles at position: ", tile_pos)
	elevations.reverse()
	return null

func get_topmost_layer_at_global_pos(pos: Vector2) -> ElevationLayer:
	elevations.reverse()
	for layer:ElevationLayer in elevations:
		var local: Vector2i = layer.local_to_map(layer.to_local(pos))
		#print("local position: ", local)
		if layer.get_cell_source_id(local) != -1:
			elevations.reverse()
			return layer
	elevations.reverse()
	return null

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
	
func translate_square_data_to_tile(data: SquareData, world_pos: Vector2i)-> void:
	var ele:int = data.elevation
	#print("loading tile: ", world_pos, " elevation: ", ele)
	if (ele >= elevations.size()):
		for x in range(elevations.size(), ele+1):
			#print_if_debug(str("creating new layer: ", x))
			var new_layer:ElevationLayer = ELEVATION_LAYER.instantiate()
			new_layer.name = str("Elevation",x)
			new_layer.elevation = x
			self.add_child(new_layer)
			#print_if_debug(str(new_layer.get_children()))
			elevations.append(new_layer)
			elevations[x].elevation = x
			elevations[x].position.y = x * -32
			
	for x in range(0, data.elevation):
		#print("building base in elevation: ", x)
		elevations[x].build_base_of(data, world_pos)
	elevations[ele].set_square(data, world_pos)
	if data.object_datas != null:
		var actual_pos := world_pos * 64 + Vector2i(data.elevation * -32, data.elevation*-32)
		object_atlas.translate_object(data.object_datas, actual_pos)

func run_shader_data_stuff(chunk_keys: Array[Vector2i]) -> void:
	#print("chunk_keys: ", chunk_keys)
	var chunks: Dictionary
	var send: bool = true
	for key in chunk_keys:
		if loaded_chunks.has(key):
			chunks[key] = loaded_chunks[key]
		else:
			#TODO: these are a good idea, but if the word is being intially loaded they will freak out
			#push_warning("Terrain Rules Handler tried to build shader data for an unloaded chunk")
			if chunks_in_loading.has(key):
				chunks[key] = chunks_in_loading[key]
			else:
				send = false
				#push_error("Terrain rules handler tried to build shader data for a chunk not even trying to load. troubling news.")
	if !chunks.is_empty() and send:
		for ele in elevations:
			ele.build_gradient_maps(chunks, chunk_keys[0])

## Runtime method for applying floors 
func apply_floor_at(square_pos: Vector2i, chunk_pos:Vector2i, floor_type: String) -> void: 
	var chunk_data:ChunkData = loaded_chunks[chunk_pos]
	if chunk_data == null:
		print("warning! tried to aplly floor at unloaded chunk: ", chunk_pos, " square: ", square_pos)
		return
	var square: SquareData = chunk_data.square_datas[square_pos]
	# if this square is null or empty, add some fake data
	if floor_type == "till": 
		## no objects, apply immediately 
		if 0 not in square.object_datas.keys():
			var overall_pos := (chunk_pos * chunk_data.chunk_size) + square_pos
			match square.type:
				SquareData.SquareType.Dirt:
					var new_floor: FloorData = FloorData.new()
					new_floor.object_id = "till"
					square.object_datas[0] = new_floor
					elevations[square.elevation].till_square(overall_pos)
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

## Runtime method for watering
func water_square_at(square_pos: Vector2i, chunk_pos:Vector2i) -> void:
	var chunk_data:ChunkData = loaded_chunks[chunk_pos]
	if chunk_data == null:
		print("warning! tried to water at unloaded chunk: ", chunk_pos, " square: ", square_pos)
		return
	#print("square_pos: ", square_pos)
	var square: SquareData = chunk_data.square_datas[square_pos]
	if square.water_saturation < 3:
		#print("old water: ", square.water_saturation)
		square.water_saturation += 1
		#print("new water: ", square.water_saturation)
		elevations[square.elevation].update_specific_pixel(chunk_pos, square_pos)

func print_if_debug(string: String) -> void:
	if debug:
		print(self.name, ":::", string)
