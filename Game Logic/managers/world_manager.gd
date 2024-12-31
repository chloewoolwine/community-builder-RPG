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
	if _world_data:
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
	var actual_pos := ((arr[0] * 64) + (arr[1] * 64 * 32)) + Vector2i(layer.elevation*-32, layer.elevation*-32) + Vector2i(32, 32)
	itemdata.object_data.position = arr[0]
	itemdata.object_data.chunk = arr[1]
	trh.object_atlas.place_object(itemdata.object_data, actual_pos, layer.elevation)
		
func check_placement_validity(ind: Indicator, player_spot:Vector2, player_layer: ElevationLayer, _item: ItemData) -> bool:
	var valid:bool = true
	
	if ind.global_position.distance_to(player_spot) > 400:
		valid = false
	# this might be broken for any layer > 0 ?
	if player_layer != trh.get_topmost_layer_at_global_pos(ind.global_position):
		valid = false
	
	#TODO: check tile type (no water!)
	#TODO: check overlapping positions
	ind.valid_place = valid
	return valid
	
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
	indicator.global_position = player_layer.map_to_local(player_layer.local_to_map(get_global_mouse_position()))
	if check_placement_validity(indicator, player_spot, player_layer, item):
		## todo: change color of indicator
		pass
	else:
		pass
	
func save_world(path: String) -> void:
	var save_result:Error = ResourceSaver.save(_world_data, path)
	if save_result != OK:
		print(save_result)
	
func deep_copy_world_data() -> WorldData:
	print("new wor;d")
	var new_world : WorldData = WorldData.new()
	new_world.world_seed = _world_data.world_seed
	new_world.chunk_size = _world_data.chunk_size
	new_world.world_size = _world_data.world_size
	
	var chunk_datas: Dictionary
	## NEED TO CHECK LOADED CHUNKS TOO- this is the same dict as unloaded chnks
	for chunk_loc:Vector2i in _world_data.chunk_datas.keys():
		print("Copying: ", chunk_loc)
		var new_chunk:ChunkData = _world_data.new()
		var old_chunk:ChunkData = _world_data.chunk_datas[chunk_loc]
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
