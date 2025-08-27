extends Node2D
class_name WorldGenerator

@warning_ignore("unused_signal")
signal save_world(world: WorldData, path: String)

const SPAWN_CHUNK:WorldData = preload("res://Test/data/world_datas/spawn_chunk.tres")

@export var world_manager: WorldManager
@export var terrain_rules_handler: TerrainRulesHandler

@export_group("WorldData properties")
@export var worldseed: int
@export var chunk_size: Vector2i = Vector2(50,50)
@export var num_chunks: Vector2i = Vector2(3,3)

@export_group("Noise generation properties")
@export var altitude_noise : FastNoiseLite
@export var moisture_noise : FastNoiseLite
@export var temperature_noise : FastNoiseLite
@export var debris_noise : FastNoiseLite
@export var alt_freq : float = 0.005
@export var oct : int = 4
@export var lac : int = 2
@export var gain : float = 0.5
@export var amplitude : float = 1.0 

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

# this is stupid, but until this has access to the Game script the emissions wont work 
var world_to_save: WorldData
var path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if worldseed == 0:
		worldseed = randi_range(1, 10000)
	# sets the seeds for the noise maps- silly but deterministic :D 
	seeder = RandomNumberGenerator.new()
	seeder.seed = worldseed
		
	#print("loading")
	#var world:WorldData = ResourceLoader.load('res://Test/data/world_datas/BIGWORLD.tres')
	#print("loading coimplete")
	##world_manager.set_world_data(world)
	var world:WorldData = generate_world_based_on_vals()
	print('time at end generation: ', Time.get_time_string_from_system())
	world_manager.set_world_data(world)
	#world_to_save = world
	#path = str('res://Test/data/world_datas/generation_test.tres')
	#save_world.emit(world, str('res://Test/data/world_datas/treez.tres'))

# a lot of this is from https://www.reddit.com/r/godot/comments/10ho9d5/any_good_tutorials_on_the_new_fastnoiselite_class/
func generate_world_based_on_vals() -> WorldData:
	var world : WorldData = WorldData.new()
	world.world_seed = self.worldseed
	world.chunk_size = chunk_size
	world.world_size = num_chunks
	print('seed = ', worldseed)
	print('chunk_size =', chunk_size)
	print('world_size =', num_chunks)
	print('time at start generation: ', Time.get_time_string_from_system())
	#Avar thread1: Thread = Thread.new()
	
	var height_grid:Dictionary = generate_heights()
	var wet_grid:Dictionary = generate_river()
	var debris_grid:Dictionary = generate_debris()
	
	world.chunk_datas = map_big_grid_to_chunks(height_grid, wet_grid, debris_grid)
	#print('world_size =', big_grid.values())
	#sand/dirt/rocks
	#do_squaretype_stuff(world)
	var spawn:ChunkData = SPAWN_CHUNK.chunk_datas[Vector2i(-1,-1)]
	spawn.chunk_position = Vector2i.ZERO
	world.chunk_datas[Vector2i(0, 0)] = spawn
	#run a single natural water pass
	print("running water calc")
	EnvironmentLogic.run_water_calc(world, world.chunk_datas.keys())
	
	print("putting down plants")
	do_squaretype_stuff(world)
	#run plant pass
	put_down_plants(world)
	
	return world

func plant_grass(_world_data: WorldData) -> void:
	pass
	
func put_down_plants(world_data: WorldData) -> void:
	var gen_data:Database = DatabaseManager.WORLD_DATABASE
	var _plants := gen_data.fetch_collection_data("GenerationData")
	var plant_rate:float = .25
	
	@warning_ignore("integer_division")
	var modx:int = num_chunks.x/2
	@warning_ignore("integer_division")
	var mody:int = num_chunks.y/2
	
	for x in num_chunks.x:
		for y in num_chunks.y:
			var chunk:ChunkData = world_data.chunk_datas[Vector2i(x-modx, y-mody)]
			
			for i in chunk_size.x:
				for j in chunk_size.y:
					var square_data:SquareData = chunk.square_datas[Vector2i(i,j)]
					var object_datas := square_data.object_data
					if square_data.water_saturation >= 4: # we dont have water plants... yet
						continue
					if object_datas.is_empty():
						if randf() < plant_rate:
							#generate plant
							var object := ObjectData.new()
							object.chunk = Vector2i(x-modx, y-mody)
							object.position = Vector2i(i,j)
							object.object_tags["age"] = 100000 #TODO: each plant needs its own age randomizer...
							object.size = Vector2i(1,1) #TODO: i still dont have different sized objects done...
							
							var plant_pool: Array[String] = create_plant_pool(square_data.water_saturation, randf() > .9)
							object.object_id = plant_pool[randi_range(0, plant_pool.size()-1)]
							if object.object_id in common_grasses or object.object_id in rare_grasses:
								square_data.object_data = [null, object, null]
								@warning_ignore("unused_variable")
								var m:int
								if object.object_id == "plant_wild_reed:":
									m = 3
								else:
									m = 0
								#poof_grass(Location.new(Vector2i(i,j), Vector2i(x-modx, y-mody)), object.object_id, m, world_data.chunk_datas)
							else:
								pass
								#square_data.object_data = [null, object, null]
							
								
	pass

func poof_grass(loc: Location, object_id: String, required_moist: int, chunks: Dictionary) -> void: 
	var all_grass:=poof_grass_recursion_helper(loc, chunks, 2)
	
	for spot in all_grass:
		var sd: SquareData = chunks[spot.chunk].square_datas[spot.position]
		if sd.water_saturation < required_moist:
			continue
		if sd.water_saturation > 3:
			continue
		if !sd.object_data.is_empty():
			#reeds should overtake grass
			if !(object_id == "plant_wild_reed" && sd.object_data[1].object_id == "plant_wild_grass"):
				continue
		var object := ObjectData.new()
		object.chunk = spot.chunk
		object.position = spot.position
		object.object_tags["age"] = 100000 #TODO: each plant needs its own age randomizer...
		object.size = Vector2i(1,1) #TODO: i still dont have different sized objects done...
		object.object_id = object_id
		sd.object_data = [null, object, null]
	pass

func poof_grass_recursion_helper(loc: Location, chunks: Dictionary, depth: int) -> Array[Location]:
	if depth <= 0:
		return []
	var matrix := loc.get_neighbor_matrix()
	var neighbors:Array[Location]
	for l:Location in matrix:
		if l.chunk in chunks.keys():
			neighbors.append(l)
			neighbors.append_array(poof_grass_recursion_helper(l, chunks, depth-1))
	
	return neighbors

func create_plant_pool(moisture: int, rare:bool) -> Array[String]:
	var final_pool:Array[String]
	var moist_varieties:Array[String]
	if moisture >= 0:
		moist_varieties.append_array(zero_moist)
	if moisture >= 1:
		moist_varieties.append_array(one_moist)
	if moisture >= 2:
		moist_varieties.append_array(two_moist)
	if moisture >= 3: 
		moist_varieties.append_array(three_moist)
	
	for vari in moist_varieties:
		if rare:
			if vari in rare_grasses or vari in rare_trees or vari in wild_crops:
				final_pool.append(vari)
		else:
			if vari in common_grasses or vari in common_trees:
				final_pool.append(vari)
	
	return final_pool

func do_squaretype_stuff(world_data: WorldData) ->void:
	var chunk_datas:=world_data.chunk_datas
	@warning_ignore("integer_division")
	var modx:int = num_chunks.x/2
	@warning_ignore("integer_division")
	var mody:int = num_chunks.y/2
	
	print("sand pass")
	for x in num_chunks.x:
		for y in num_chunks.y:
			var chunk:ChunkData = chunk_datas[Vector2i(x - modx, y - mody)]
			#if x == q_x and y == q_y:
				#continue
			for i in chunk_size.x:
				for j in chunk_size.y:
					var square : SquareData= chunk.square_datas[Vector2i(i,j)]
					if square.type == SquareData.SquareType.Sand:
							#populate more sand
							populate_sand_logic(square, chunk, chunk_datas)
	#
	#for x in num_chunks.x:
		#for y in num_chunks.y:
			#var chunk:ChunkData = chunk_datas[Vector2i(x - modx, y - mody)]
			##if x == q_x and y == q_y:
				##continue
			#for i in range(chunk_size.x-1, -1, -1):
				#for j in range(chunk_size.y-1, -1, -1):
					#var square : SquareData= chunk.square_datas[Vector2i(i,j)]
					#if square.type == SquareData.SquareType.Sand:
							##populate more sand
						#populate_sand_logic(square, chunk, chunk_datas)
	#TODO: dirt pass

@warning_ignore("unused_parameter")
func map_big_grid_to_chunks(big_grid:Dictionary,wet_grid:Dictionary, debris_grid:Dictionary) ->  Dictionary[Vector2i, ChunkData]:
	var chunk_datas: Dictionary[Vector2i, ChunkData]
	
	@warning_ignore("integer_division")
	var modx:int = num_chunks.x/2
	@warning_ignore("integer_division")
	var mody:int = num_chunks.y/2
	
	for x in num_chunks.x:
		for y in num_chunks.y:
			#get all values in chunk (x,y)
			var chunk:ChunkData = ChunkData.new()
			chunk.chunk_size = chunk_size
			chunk.chunk_position = Vector2i(x - modx, y - mody)
			#var moist:float = wet_grid[Vector2i(x,y)]
			#var temp:float = temp_grid[Vector2i(x,y)]
			#var debris:float = debris_grid[Vector2i(x,y)]
			#
			#if(moist > .5): 
				#if(temp > .5):
					#if(debris > .5):
						#chunk.biome = ChunkData.Biome.EvilWetland
					#else:
						#chunk.biome = ChunkData.Biome.Wetland
				#else:
					#if(debris > .5):
						#chunk.biome = ChunkData.Biome.Forest
					#else:
						#chunk.biome = ChunkData.Biome.Deepforest
			#else:
				#if(temp > .5):
					#if(debris > .5):
						#chunk.biome = ChunkData.Biome.Wasteland
					#else:
						#chunk.biome = ChunkData.Biome.Shrubland
				#else:
					#if(debris > .5):
						#chunk.biome = ChunkData.Biome.Cityscape
					#else:
						#chunk.biome = ChunkData.Biome.Grassland
			#if chunk.biome != ChunkData.Biome.Wetland:
			# everything is a forest, for now 
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
					square.water_saturation = wet_grid[big_pos] if big_pos in wet_grid.keys() else 0
					#square.elevation = 0
					square.location_in_chunk = Vector2i(i,j)
					square_datas[Vector2i(i,j)] = square
					square.type = SquareData.SquareType.Dirt
					square.pollution = debris_grid[big_pos]
					
			chunk.square_datas = square_datas
			chunk_datas[chunk.chunk_position] = chunk
	
	
	#print("picking random chunk as quarry")
	##TODO: blobular shape
	#var q_x := randi_range(1, num_chunks.x-2)
	#var q_y := randi_range(1, num_chunks.y-2)
	#var quarry_chunk: ChunkData = chunk_datas[Vector2i(q_x-modx,q_y - mody)]
	#for i in chunk_size.x:
		#for j in chunk_size.y:
			#var square: SquareData = quarry_chunk.square_datas[Vector2i(i,j)]
			#square.type = SquareData.SquareType.Rock
			#square.elevation = square.elevation + 1
	
	return chunk_datas 

func populate_sand_logic(square: SquareData, chunk: ChunkData, chunks: Dictionary) -> void: 
	var loc := Location.new(square.location_in_chunk, chunk.chunk_position)
	var matrix := loc.get_neighbor_matrix()
	var water_touch:bool = false
	var neighbors:Array[Location]
	for l:Location in matrix:
		if l.chunk in chunks.keys():
			neighbors.append(l)
	#print("niehgbors: ", neighbors)
	for neigh:Location in neighbors:
		var s:SquareData = chunks[neigh.chunk].square_datas[neigh.position]
		if s.water_saturation > 3:
			water_touch = true
	if square.water_saturation > 3:
		water_touch = true

	for neigh:Location in neighbors:
		var s:SquareData = chunks[neigh.chunk].square_datas[neigh.position]
		if s.type == SquareData.SquareType.Sand:
			return
		if water_touch:
			if randf() > .05:
				s.type = SquareData.SquareType.Sand
		else:
			if randf() > .9:
				s.type = SquareData.SquareType.Sand
	pass

## Generates on square-by-square basis
@warning_ignore("shadowed_global_identifier")
func generate_heights() -> Dictionary:
	var rng := seeder
	rng.seed = worldseed
	var total_tiles := chunk_size * (num_chunks + Vector2i(2,2)) # add buffer chunks on each side 
	print("total tiles: ", total_tiles)
	altitude_noise.set_seed(worldseed)
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


@warning_ignore("shadowed_global_identifier")
func generate_river() -> Dictionary:
	altitude_noise.seed = seeder.randi_range(0, 10000)
	var grid :Dictionary = {}
	var total_tiles := chunk_size * (num_chunks + Vector2i(2,2))
	@warning_ignore("integer_division")
	var start_x := seeder.randi_range(total_tiles.x/2 + 32, total_tiles.x) # ensure right side (i think lol)
	
	var brush:Brush = Brush.new(12, Vector2i(start_x, 0))
	brush.rand = moisture_noise # crazy !
	brush.min_r = 7
	brush.max_r = 13
	#for tile:Vector2i in brush.get_pix():
		#grid[tile] = 4 #ill deal with deep water later LOL TODO: deep water gen
	for y in total_tiles.y:
		var tiles:Array[Vector2i]
		if altitude_noise.get_noise_1d(y) > 0:
			tiles = brush.next(Vector2i(1, 1))
		else:
			tiles = brush.next(Vector2i(-1, 1))
		for tile:Vector2i in tiles:
			#print("brush center:", brush.position, " tile:", tile)
			grid[tile] = 4 #ill deal with deep water later LOL TODO: deep water gen
	return grid

## Generates on chunk-by-chunk basis- used for determining biome
@warning_ignore("shadowed_global_identifier")
func generate_debris() -> Dictionary:
	debris_noise.set_seed(worldseed)
	var counts:Dictionary[int, int]
	var total_tiles := chunk_size * (num_chunks + Vector2i(2,2)) 
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
