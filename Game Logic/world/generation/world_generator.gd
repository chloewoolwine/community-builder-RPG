extends Node2D
class_name WorldGenerator

@warning_ignore("unused_signal")
signal save_world(world: WorldData, path: String)

const SPAWN_CHUNK:WorldData = preload("res://Test/data/world_datas/spawn_chunk.tres")

@export var world_manager: WorldManager
@export var terrain_rules_handler: TerrainRulesHandler
@export var ON: bool = false

@export_group("WorldData properties")
@export var worldseed: int
@export var chunk_size: Vector2i = Vector2(50,50)
@export var num_chunks: Vector2i = Vector2(3,3)

@export_group("Noise generation properties")
@export var altitude_noise : FastNoiseLite
@export var moisture_noise : FastNoiseLite
@export var debris_noise : FastNoiseLite
@export var plant_noise : FastNoiseLite

@export_group("Plant Population Properties")
@export var zero_moist: Array[String]
@export var one_moist: Array[String]
@export var two_moist: Array[String]
@export var three_moist: Array[String]

@export var common_grasses: Array[String]
@export var rare_grasses: Array[String]

@export var common_trees: Array[String]
@export var rare_trees: Array[String]

@export var wild_crops: Array[String]

var seeder:RandomNumberGenerator

var grass_noise: FastNoiseLite
var tree_noise: FastNoiseLite

var world_to_save: WorldData
var path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ON:
		var world:WorldData = generate_world_based_on_vals()
		world_manager.set_world_data(world)
		
		## old loading stuff
		#print("loading")
		#var world:WorldData = ResourceLoader.load('res://Test/data/world_datas/BIGWORLD.tres')
		#print("loading coimplete")
		#world_to_save = world
		#path = str('res://Test/data/world_datas/generation_test.tres')
		#save_world.emit(world, str('res://Test/data/world_datas/treez.tres'))
		save_world.emit(world, str(''))
	pass

# a lot of this is from https://www.reddit.com/r/godot/comments/10ho9d5/any_good_tutorials_on_the_new_fastnoiselite_class/
func generate_world_based_on_vals() -> WorldData:
	print('time at start generation: ', Time.get_time_string_from_system())
	set_randomness()
	var world : WorldData = WorldData.new()
	world.world_seed = self.worldseed
	world.chunk_size = chunk_size
	world.world_size = num_chunks
	print('seed = ', worldseed)
	print('chunk_size =', chunk_size)
	print('world_size =', num_chunks)
	#Avar thread1: Thread = Thread.new() TODO: threads !
	
	var height_grid:Dictionary = generate_heights()
	var wet_grid:Dictionary = generate_river()
	var debris_grid:Dictionary = generate_debris()
	
	world.chunk_datas = map_big_grid_to_chunks(height_grid, wet_grid, debris_grid)
	print("running water calc")
	EnvironmentLogic.run_water_calc(world, world.chunk_datas.keys())
	do_squaretype_stuff(world)
	world = fix_spawn_chunk(world)
	#run a single natural water pass
	print("running water calc 2")
	EnvironmentLogic.run_water_calc(world, world.chunk_datas.keys())
	
	#run plant pass
	#put_down_plants(world)
	print('time at end generation: ', Time.get_time_string_from_system())
	return world

static func fix_spawn_chunk(data: WorldData) -> WorldData:
	var spawn:ChunkData = SPAWN_CHUNK.chunk_datas[Vector2i(-1,-1)]
	spawn.chunk_position = Vector2i.ZERO
	var old_chunk := data.chunk_datas[Vector2i(0,0)]
	for s_key:Vector2i in old_chunk.square_datas.keys():
		var old_square:SquareData = old_chunk.square_datas[s_key]
		var spawn_square:SquareData = spawn.square_datas[s_key]
		spawn_square.elevation = old_square.elevation
		spawn_square.pollution = old_square.pollution
		#don't want any waterfalls, cuz they dont have sprites yet
		if spawn_square.water_saturation >= Constants.SHALLOW_WATER:
			var locs := Location.new(s_key, Vector2i(0,0)).get_neighbor_matrix()
			for loc in locs:
				var square := EnvironmentLogic.get_square(data, loc)
				square.elevation = spawn_square.elevation
		if spawn_square.water_saturation < Constants.SHALLOW_WATER && (spawn_square.type == SquareData.SquareType.Grass || spawn_square.type == SquareData.SquareType.Dirt):
			spawn_square.object_data = old_square.object_data
		else:
			spawn_square.object_data = [null,null,null,null] #sorry little building :/
	data.chunk_datas[Vector2i(0, 0)] = spawn
	return data

func set_randomness() -> void:
	if worldseed == 0:
		worldseed = randi_range(1, 10000)
	# sets the seeds for the noise maps- silly but deterministic :D 
	seeder = RandomNumberGenerator.new()
	seeder.seed = worldseed
	altitude_noise.set_seed(seeder.randi_range(0, 10000))
	moisture_noise.set_seed(seeder.randi_range(0, 10000))
	debris_noise.set_seed(seeder.randi_range(0, 10000))
	grass_noise = plant_noise.duplicate(true)
	grass_noise.set_seed(seeder.randi_range(0, 10000))
	tree_noise = plant_noise.duplicate(true)
	tree_noise.set_seed(seeder.randi_range(0, 10000))

# idea to make this a little less uniform 
# instead of filling All of "grass noise" with possible grasses
# create brush strokes and then fill those brush strokes with grass
var grasses := DatabaseManager.fetch_plant_category(&"grass")
func plant_grass(world_data: WorldData, loc: Location) -> String:
	var square := EnvironmentLogic.get_square(world_data, loc)
	if square.object_data != null && square.object_data.size() > 1 && square.object_data[1] != null:
		return ""
	var valids:Dictionary[int, bool]
	
	for x:int in grasses:
		valids[x] = true
	for x:int in grasses:
		var plant:PlantGenData = grasses[x]
		if square.water_saturation < plant.target_moisture:
			valids[x] = false
		if square.water_saturation > 3:
			#print("wet tile at ", loc)
			if !plant.shallow_water:
				#print("plant ", plant.object_id, " rejected")
				valids[x] = false
		if square.pollution > plant.pollution_tolerance:
			valids[x] = false
		if square.type == SquareData.SquareType.Sand && SquareData.SquareType.Sand not in plant.target_tiles:
			valids[x] = false
		#other factors
	#for x:int in grasses:
		#print(grasses[x].object_id)
	#print(valids)
	for x:int in grasses.keys():
		if !valids[x]:
			valids.erase(x)
	
	if valids.keys().is_empty():
		#barren ass wasteland
		return ""

	var w_loc := loc.get_world_coordinates()
	#print("grass noise at loc: ", grass_noise.get_noise_2d(w_loc.x, w_loc.y))
	# low - like -.1 ~ .1 ish
	#theres probably a better way than to map this by hand, but, eh, 
	var noise:= grass_noise.get_noise_2d(w_loc.x, w_loc.y)
	var target:int
	if abs(noise) > .5:
		target = 5
	elif abs(noise) > .4:
		target = 4
	elif abs(noise) > .3:
		target = 3
	elif abs(noise) > .2:
		target = 2
	else:
		target = 1
	
	var targets:Array[PlantGenData]
	while target >= 0 && targets.is_empty():
		for x:int in valids:
			if grasses[x].rarity == target:
				targets.append(grasses[x])
		target = target-1
	
	if targets.is_empty():
		#print("no valid plant for square ", loc)
		return ""
	
	var final:PlantGenData
	#idk if this random thing will ever be used tbh. 
	final = targets[randi_range(0, targets.size()-1)]
	
	#print(final.object_id)
	EnvironmentLogic.place_object_data(world_data, loc, StringName(final.object_id), 10000)
	return final.object_id

var trees := DatabaseManager.fetch_plant_category(&"tree")
func plant_tree(world_data: WorldData, loc: Location) -> String:
	var square := EnvironmentLogic.get_square(world_data, loc)
	if square.object_data != null && square.object_data.size() > 1 && square.object_data[1] != null:
		var obj:ObjectData = square.object_data[1]
		if obj.object_id == Constants.POINTER:
			return ""
		if obj.size.x > 1 || obj.size.y > 1:
			return ""
	
	var valids:Dictionary[int, bool]
	
	for x:int in trees:
		valids[x] = true
	for x:int in trees:
		var plant:PlantGenData = trees[x]
		if square.water_saturation < plant.target_moisture:
			valids[x] = false
		if square.water_saturation > 3:
			#print("wet tile at ", loc)
			if !plant.shallow_water:
				#print("plant ", plant.object_id, " rejected")
				valids[x] = false
		if square.pollution > plant.pollution_tolerance:
			valids[x] = false
		if square.type == SquareData.SquareType.Sand && SquareData.SquareType.Sand not in plant.target_tiles:
			valids[x] = false
	
	#print("valids ", valids)
	for x:int in trees.keys():
		if !valids[x]:
			valids.erase(x)
	
	if valids.keys().is_empty():
		#barren ass wasteland
		return ""
	var final:PlantGenData
	#idk if this random thing will ever be used tbh. 
	final = trees[valids.keys()[randi_range(0, valids.keys().size()-1)]]
	
	#print(final.object_id)
	#always get the final stage- maybe fix this later probably
	EnvironmentLogic.place_object_data(world_data, loc, StringName(final.object_id + str(final.stage_minutes.size()-1)), 100000, true)
	return final.object_id

func do_squaretype_stuff(world_data: WorldData) ->void:
	var chunk_datas:=world_data.chunk_datas
	var all_grasses:Dictionary[String, int]
	var all_trees:Dictionary[String, int]
	
	for c_key:Vector2i in chunk_datas.keys():
		var chunk:ChunkData = chunk_datas[c_key]
		for s_key in chunk.square_datas:
			var square := chunk.square_datas[s_key]
			if square.pollution < 4 && square.type == SquareData.SquareType.Dirt:
				square.type = SquareData.SquareType.Grass
			var grass := plant_grass(world_data, Location.new(s_key, c_key))
			var gcount:int = all_grasses.get_or_add(grass, 0)
			all_grasses[grass] = gcount+1
			if seeder.randf() > .9:
				var tree := plant_tree(world_data, Location.new(s_key, c_key))
				var tcount:int = all_trees.get_or_add(tree, 0)
				all_trees[tree] = tcount+1

	#print(trees)
	print("grasses planted: ", all_grasses)
	print("trees planted: ", all_trees)

@warning_ignore("unused_parameter")
func map_big_grid_to_chunks(big_grid:Dictionary,wet_grid:Dictionary, debris_grid:Dictionary) ->  Dictionary[Vector2i, ChunkData]:
	var chunk_datas: Dictionary[Vector2i, ChunkData]
	
	@warning_ignore("integer_division")
	var modx:int = num_chunks.x/2
	@warning_ignore("integer_division")
	var mody:int = num_chunks.y/2
	
	var sand_grid: Dictionary[Vector2i, bool]
	
	var sand_brush:Brush = Brush.new(15, sand_positions[0], 0)
	sand_brush.rand = moisture_noise 
	sand_brush.min_r = 10
	sand_brush.max_r = 20
	for pos in sand_positions:
		var tiles:=sand_brush.next_force_pos(pos)
		for tile in tiles:
			sand_grid[tile] = true
	
	for x in num_chunks.x:
		for y in num_chunks.y:
			#get all values in chunk (x,y)
			var chunk:ChunkData = ChunkData.new()
			chunk.chunk_size = chunk_size
			chunk.chunk_position = Vector2i(x - modx, y - mody)
			#var moist:float = wet_grid[Vector2i(x,y)]
			#var temp:float = temp_grid[Vector2i(x,y)]
			#var debris:float = debris_grid[Vector2i(x,y)]
			chunk.biome = chunk.Biome.Forest
			
			var square_datas: Dictionary[Vector2i, SquareData]
			for i in chunk_size.x:
				for j in chunk_size.y:
					@warning_ignore("unused_variable")
					var total_x : int = (x * chunk_size.x) + i
					@warning_ignore("unused_variable")
					var total_y : int = (y * chunk_size.y) + j
					#if big_grid[Vector2i(total_x, total_y)] == 0:
					#print("total x : ", x, "total y: ",y, "elevation:", big_grid[Vector2i(total_x, total_y)])
					var square:SquareData = SquareData.new()
					var big_pos := Vector2i(total_x, total_y)
					square.elevation = big_grid[big_pos]
					square.water_saturation = wet_grid.get(big_pos, 0)
					#square.elevation = 0
					square.location_in_chunk = Vector2i(i,j)
					square_datas[Vector2i(i,j)] = square
					square.type = SquareData.SquareType.Sand if big_pos in sand_grid.keys() else SquareData.SquareType.Dirt
					square.pollution = debris_grid[big_pos]
					
			chunk.square_datas = square_datas
			chunk_datas[chunk.chunk_position] = chunk
	
	return chunk_datas 

## Generates on square-by-square basis
@warning_ignore("shadowed_global_identifier")
func generate_heights() -> Dictionary:
	var total_tiles := chunk_size * (num_chunks) 
	print("total tiles: ", total_tiles)
	var grid:Dictionary[Vector2i, int]
	for x in total_tiles.x:
		for y in total_tiles.y:
			grid[Vector2i(x,y)] = 1

	var zero_brush:Brush = Brush.new(10, Vector2i(10, total_tiles.y - 160)) #bottom left
	zero_brush.max_r = 150
	for x in total_tiles.x:
		#print("brush at ", zero_brush.position, " radius: ", zero_brush.radius)
		#finish the hill
		for y in range(zero_brush.position.y, total_tiles.y):
			grid[Vector2i(zero_brush.position.x, y)] = 0
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(x) > 0:
			tiles = zero_brush.next(Vector2i(1, 1), false)
		else:
			tiles = zero_brush.next(Vector2i(1, -1), false)
		#this is to get the nice edge
		for tile:Vector2i in tiles:
			if tile.x > 0 && tile.x <= total_tiles.x && tile.y > 0 && tile.y <= total_tiles.y:
				grid.erase(tile)
				grid[tile] = 0
	for y in range(zero_brush.position.y, total_tiles.y):
		grid[Vector2i(zero_brush.position.x, y)] = 0
	
	var two_brush:Brush = Brush.new(10, Vector2i(10, total_tiles.y - 260)) #bottom left
	two_brush.max_r = 150
	#two_brush.random_factor = 5
	for x in total_tiles.x:
		#print("brush at ", two_brush.position, " radius: ", two_brush.radius)
		#finish the hill
		for y in range(two_brush.position.y, 0, -1):
			grid[Vector2i(two_brush.position.x, y)] = 2
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(x + (total_tiles.x*1)) > 0:
			tiles = two_brush.next(Vector2i(1, 1), false)
		else:
			tiles = two_brush.next(Vector2i(1, -1), false)
		#this is to get the nice edge
		for tile:Vector2i in tiles:
			if tile.x > 0 && tile.x <= total_tiles.x && tile.y > 0 && tile.y <= total_tiles.y:
				grid.erase(tile)
				grid[tile] = 2
	for y in range(two_brush.position.y, 0, -1):
		grid[Vector2i(two_brush.position.x, y)] = 2
		
	var three_brush:Brush = Brush.new(10, Vector2i(10, total_tiles.y - 315)) #bottom left
	three_brush.max_r = 150
	#two_brush.random_factor = 5
	for x in total_tiles.x:
		#print("brush at ", three_brush.position, " radius: ", three_brush.radius)
		#finish the hill
		for y in range(three_brush.position.y, 0, -1):
			grid[Vector2i(three_brush.position.x, y)] = 3
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(x + (total_tiles.x*2)) > 0:
			tiles = three_brush.next(Vector2i(1, 1), false)
		else:
			tiles = three_brush.next(Vector2i(1, -1), false)
		#this is to get the nice edge
		for tile:Vector2i in tiles:
			if tile.x > 0 && tile.x <= total_tiles.x && tile.y > 0 && tile.y <= total_tiles.y:
				grid.erase(tile)
				grid[tile] = 3
	for y in range(three_brush.position.y, 0, -1):
		grid[Vector2i(three_brush.position.x, y)] = 3
	
	var four_brush:Brush = Brush.new(10, Vector2i(10, total_tiles.y - 320)) #bottom left
	four_brush.max_r = 150
	#two_brush.random_factor = 5
	for x in total_tiles.x:
		#print("brush at ", four_brush.position, " radius: ", four_brush.radius)
		#finish the hill
		for y in range(four_brush.position.y, 0, -1):
			grid[Vector2i(four_brush.position.x, y)] = 4
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(x + (total_tiles.x*3)) > 0:
			tiles = four_brush.next(Vector2i(1, 1), false)
		else:
			tiles = four_brush.next(Vector2i(1, -1), false)
		#this is to get the nice edge
		for tile:Vector2i in tiles:
			if tile.x > 0 && tile.x <= total_tiles.x && tile.y > 0 && tile.y <= total_tiles.y:
				grid.erase(tile)
				grid[tile] = 4
	
	for y in range(four_brush.position.y, 0, -1):
		grid[Vector2i(four_brush.position.x, y)] = 4
	return grid

var sand_positions: Array[Vector2i]
@warning_ignore("shadowed_global_identifier")
func generate_river() -> Dictionary:
	var grid :Dictionary = {}
	var total_tiles := chunk_size * (num_chunks)
	@warning_ignore("integer_division")
	var start_x := seeder.randi_range(total_tiles.x/2 + 32, total_tiles.x - 32) # ensure right side (i think lol)
	
	var brush:Brush = Brush.new(12, Vector2i(start_x, 0))
	brush.rand = moisture_noise # crazy !
	brush.min_r = 7
	brush.max_r = 13
	sand_positions.append(Vector2i(start_x,0))
	for y in total_tiles.y:
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(y) > 0:
			tiles = brush.next(Vector2i(1, 1))
			sand_positions.append(brush.position)
		else:
			tiles = brush.next(Vector2i(-1, 1))
			sand_positions.append(brush.position)
		for tile:Vector2i in tiles:
			#print("brush center:", brush.position, " tile:", tile)
			grid[tile] = 4 #ill deal with deep water later LOL TODO: deep water gen
	return grid

## Generates on chunk-by-chunk basis- used for determining biome
@warning_ignore("shadowed_global_identifier")
func generate_debris() -> Dictionary:
	var counts:Dictionary[int, int]
	var total_tiles := chunk_size * (num_chunks) 
	var grid :Dictionary = {}
	for x in total_tiles.x:
		for y in total_tiles.y:
			var val:int = (abs(debris_noise.get_noise_2d(x, y)) + .15) * 4
			grid[Vector2i(x,y)] = val
			if val in counts.keys():
				counts[val] = counts[val] + 1
			else:
				counts[val] = 1
	print("pollution counts: ", counts)
	
	return grid
