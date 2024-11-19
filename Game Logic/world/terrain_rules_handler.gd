extends Node2D
class_name TerrainRulesHandler

const ELEVATION_LAYER = preload("res://Scenes/world/elevation_layer.tscn")
## Going to have to change this later when i figure out the biome shit. thats a problem for future me
const RUINED_PLAINS_BIOME = preload("res://Scenes/world/tilesets/ruined_plains_biome.tres")
@export var elevations: Array[ElevationLayer]
@export var debug: bool = false
signal chunk_loaded(chunk: ChunkData)
signal chunk_unloaded(chunk: ChunkData)

func _ready() -> void:
	for child in get_children():
		if child is ElevationLayer and !elevations.has(child):
			elevations.append(child)
	for x in elevations.size():
		elevations[x].elevation = x
		elevations[x].position.y = x * -32

func get_tileset_pos_from_global(global_pos: Vector2)->Vector2i:
	return elevations[0].local_to_map(global_pos)

func get_topmost_layer_at_pos(pos: Vector2i) -> ElevationLayer:
	elevations.reverse()
	var tile_pos: Vector2i = get_tileset_pos_from_global(pos)
	for layer in elevations:
		if layer.get_cell_source_id(tile_pos) != -1:
			elevations.reverse()
			return layer
	#push_error("Error: couldn't find any tiles at position: ", tile_pos)
	return null

func unload_set_of_chunks(chunks: Dictionary) -> void:
	for chunki:Vector2i in chunks.keys():
		#print_if_debug(str("unloading chunk: ", chunks[chunki].chunk_position))
		unload_chunk(chunks[chunki])
		
func populate_set_of_chunks(chunks: Dictionary) -> void:
	for chunki:Vector2i in chunks:
		#print("loading chunk: ", chunks[chunki].chunk_position)
		load_chunk(chunks[chunki])

func load_chunk(chunk: ChunkData) -> void:
	# populate tiles
	# print("loading chunk: ", chunk.chunk_position)
	for square_key:Vector2i in chunk.square_datas.keys():
		var square: SquareData = chunk.square_datas[square_key]
		var pos:Vector2i = chunk.chunk_position * chunk.chunk_size
		pos = pos + square.location_in_chunk
		translate_square_data_to_tile(square, pos)
	chunk_loaded.emit(chunk)
	
	
func translate_square_data_to_tile(data: SquareData, _actual_pos: Vector2i)-> void:
	#print("loading tile: ", _actual_pos)
	var ele:int = data.elevation
	if (ele >= elevations.size()):
		for x in range(elevations.size(), ele+1):
			print_if_debug(str("creating new layer: ", x))
			var new_layer:ElevationLayer = ELEVATION_LAYER.instantiate()
			new_layer.name = str("Elevation",x)
			new_layer.elevation = x
			self.add_child(new_layer)
			#print_if_debug(str(new_layer.get_children()))
			elevations.append(new_layer)
			elevations[x].elevation = x
			elevations[x].position.y = x * -32
		
	while ele > -1:
		elevations[ele].set_square(data, _actual_pos)
		ele = ele - 1
	
func unload_chunk(chunk: ChunkData)->void:
	var chunk_start_loc:Vector2i = chunk.chunk_position * chunk.chunk_size
	
	for square_key:Vector2i in chunk.square_datas.keys():
		var square: SquareData = chunk.square_datas[square_key]
		var pos: Vector2i= chunk_start_loc + square.location_in_chunk
		for ele in elevations:
			ele.delete_square(pos)
	
	chunk_unloaded.emit(chunk)
 
func print_if_debug(string: String) -> void:
	if debug:
		print(self.name, ":::", string)
