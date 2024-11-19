extends Node2D
class_name WorldManager

#may need to do a list of chunk datas, in case multiple chunks chage at once?
							
signal crop_placed(crop: Crop)
#signal plant_placed(crop: Crop)

@export var world_data: WorldData:
	set(value):
		world_data = value
		set_world_data(value)
@export var world_edit_mode: bool = false
@export var load_chunks: bool = false
@export var unload_chunks: bool = false
@onready var terrain_rules_handler: TerrainRulesHandler = $TerrainRulesHandler

var player: Player
var loaded_chunks: Dictionary

func _ready() -> void:
	terrain_rules_handler.chunk_loaded.connect(set_chunk_loaded)
	terrain_rules_handler.chunk_unloaded.connect(set_chunk_unloaded)
	
	if(world_data != null):
		set_world_data(world_data)

func _process(_delta: float) -> void:
	if world_data:
		if world_edit_mode:
			load_and_unload_chunks_surronding_point($"../Camera2D".get_global_position())
		elif player and load_chunks:
			load_and_unload_chunks_surronding_point(player.get_global_position())
	
func set_world_data(new_world: WorldData) -> void:
	print("world data recieved, new world seed: ", new_world.world_seed, " \n chunks to unload: ", loaded_chunks.keys(), " \n number of new chunks: ", new_world.chunk_datas.size())
	terrain_rules_handler.unload_set_of_chunks(loaded_chunks)
	while(loaded_chunks.size() > 0):
		pass #this is silly but idk how else to do it and i dont feel like looking it up
	print("new world chunk datas: ", new_world.chunk_datas)
	
func set_chunk_unloaded(chunk: ChunkData) -> void:
	#print("chunk is unloaded: ", chunk.chunk_position)
	loaded_chunks.erase(chunk.chunk_position)
	
func set_chunk_loaded(chunk: ChunkData) -> void:
	loaded_chunks[chunk.chunk_position] = chunk
	#print("world data chunks afer loading: ", world_data.chunk_datas[chunk.chunk_position])
	#print("chunk is loaded: ", chunk.chunk_position)
	
func load_and_unload_chunks_surronding_point(point: Vector2) -> void:
	var surronding_chunks:Array[Vector2i] = get_chunks_surronding_point(point)
	var chunks_to_load:Dictionary
	for chunk:Vector2i in surronding_chunks:
		if !loaded_chunks.has(chunk) && world_data.chunk_datas.has(chunk):
			chunks_to_load[chunk] = world_data.chunk_datas[chunk]
			
	var chunks_to_unload:Dictionary
	for loaded_chunk:Vector2i in loaded_chunks:
		if !surronding_chunks.has(loaded_chunk):
			chunks_to_unload[loaded_chunk] = loaded_chunks[loaded_chunk]

	if load_chunks:
		terrain_rules_handler.populate_set_of_chunks(chunks_to_load)
	if unload_chunks:
		terrain_rules_handler.unload_set_of_chunks(chunks_to_unload)

func get_chunks_surronding_point(pos: Vector2) -> Array[Vector2i]:
	var tileset_pos:Vector2i = terrain_rules_handler.get_tileset_pos_from_global(pos)
	#print("tileset_pos = ", tileset_pos)
	var player_chunk:Vector2i = tileset_pos/world_data.chunk_size
	if tileset_pos.x < 0:
		player_chunk.x -= 1
	if tileset_pos.y < 0:
		player_chunk.y -= 1
	
	#print("player chunk = ", player_chunk)
	
	return [player_chunk, player_chunk + Vector2i(0, 1), player_chunk + Vector2i(0, -1), player_chunk + Vector2i(1, 0),
	player_chunk + Vector2i(-1, 0), player_chunk + Vector2i(1, 1), player_chunk + Vector2i(-1, 1),
	player_chunk + Vector2i(1, -1), player_chunk + Vector2i(-1, -1)]
	
## Callback function to send layer [int] to the function [callback]
func give_requested_layer(layer:int, callback: Callable) -> void:
	#print("requested layer: ", layer)
	#print("callback func: ", callback.get_method())
	if layer < 0:
		callback.call(terrain_rules_handler.elevations[0])
	elif layer > terrain_rules_handler.elevations.size():
		callback.call(terrain_rules_handler.elevations[terrain_rules_handler.elevations.size()-1])
	else: 
		callback.call(terrain_rules_handler.elevations[layer])

#TODO: may have to change the name of "crop" component to just "plant"
#and add crop functionality in another subclass
#this may get sticky if i do not do that
func place_object(pos: Vector2, layer:ElevationLayer, itemdata: ItemData)->void:
	if itemdata is ItemDataSeed:
		var object := load(str("res://Scenes/objects/crop/", itemdata.plant_name, ".tscn"))
		#TODO: when tilemaplayers come out check to see if an object can be planted before doing it
		@warning_ignore("untyped_declaration")
		var plant = object.instantiate()
		plant.global_position = pos
		layer.add_child(plant)
		crop_placed.emit(plant)
		
func check_placement_validity(ind: Indicator, player_spot:Vector2, player_layer: ElevationLayer, _item: ItemData) -> bool:
	var valid:bool = true
	
	#TODO: check if objects are on top of each other here
	if ind.global_position.distance_to(player_spot) > 400:
		valid = false
	
	if player_layer != terrain_rules_handler.get_topmost_layer_at_pos(ind.global_position):
		valid = false
	
	#TODO: check tile type
	
	ind.valid_place = valid
	return valid
	
func move_indicator(indicator: Indicator, player_spot: Vector2, item: ItemData)-> void:
	var player_layer: ElevationLayer = player.elevation_handler.current_map_layer
	indicator.global_position = player_layer.map_to_local(player_layer.local_to_map(get_global_mouse_position()))
	check_placement_validity(indicator, player_spot, player_layer, item)
	
func save_world(path: String) -> void:
	var save_result:Error = ResourceSaver.save(world_data, path)
	if save_result != OK:
		print(save_result)
	
func deep_copy_world_data() -> WorldData:
	print("new wor;d")
	var new_world : WorldData = WorldData.new()
	new_world.world_seed = world_data.world_seed
	new_world.chunk_size = world_data.chunk_size
	new_world.world_size = world_data.world_size
	
	var chunk_datas: Dictionary
	## NEED TO CHECK LOADED CHUNKS TOO- this is the same dict as unloaded chnks
	for chunk_loc:Vector2i in world_data.chunk_datas.keys():
		print("Copying: ", chunk_loc)
		var new_chunk:ChunkData = ChunkData.new()
		var old_chunk:ChunkData = world_data.chunk_datas[chunk_loc]
		new_chunk.chunk_size = Vector2i(old_chunk.chunk_size.x,old_chunk.chunk_size.y)
		new_chunk.chunk_position = Vector2i(old_chunk.chunk_position.x,old_chunk.chunk_position.y)
		new_chunk.biome = old_chunk.biome
		var square_datas: Dictionary
		for square_loc:Vector2i in old_chunk.square_datas.keys():
			#print("Copying: ", square_loc)
			var new_square:SquareData = SquareData.new()
			var old_square:SquareData = old_chunk.square_datas[square_loc]
			new_square.elevation = old_square.elevation
			new_square.fertility = old_square.fertility
			new_square.location_in_chunk = Vector2i(old_square.location_in_chunk.x,old_square.location_in_chunk.y)
			new_square.type = old_square.type
			new_square.water_saturation = old_square.water_saturation
			square_datas[new_square.location_in_chunk] = new_square
		new_chunk.square_datas = square_datas
		chunk_datas[new_chunk.chunk_position] = new_chunk
	new_world.chunk_datas = chunk_datas
	print("copied chunks: ", chunk_datas.keys())
	return new_world
