extends Node2D
class_name WorldGenerator

signal save_world(world: WorldData, path: String)

@export var world_manager: WorldManager
@export var terrain_rules_handler: TerrainRulesHandler

@export_group("WorldData properties")
@export var worldseed: int
@export var chunk_size: Vector2i = Vector2(50,50)
@export var num_chunks: Vector2i = Vector2(3,3)
@export var acceptable_objects: Array[ObjectData]

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

var seed_generator:RandomNumberGenerator

# this is stupid, but until this has access to the Game script the emissions wont work 
var world_to_save: WorldData
var path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if worldseed == 0:
		worldseed = randi_range(1, 10000)
	# sets the seeds for the noise maps- silly but deterministic :D 
	seed_generator = RandomNumberGenerator.new()
	seed_generator.seed = worldseed
		
	#print("loading")
	#var world:WorldData = ResourceLoader.load('res://Test/data/world_datas/BIGWORLD.tres')
	#print("loading coimplete")
	#world_manager.set_world_data(world)
	var world:WorldData = generate_world_based_on_vals()
	print('time at end generation + save: ', Time.get_time_string_from_system())
	world_manager.set_world_data(world)
	world_to_save = world
	path = str('res://Test/data/world_datas/treez.tres')
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
	
	var f1:int = seed_generator.randi_range(0, 10000)
	var f2:int = seed_generator.randi_range(0, 10000)
	var f3:int = seed_generator.randi_range(0, 10000)
	var f4:int = seed_generator.randi_range(0, 10000)
	
	#Avar thread1: Thread = Thread.new()
	
	var height_grid:Dictionary = generate_heights(f1)
	var wet_grid:Dictionary = generate_moisture(f2)
	var temp_grid:Dictionary = generate_temperature(f3)
	var debris_grid:Dictionary = generate_debris(f4)
	
	world.chunk_datas = map_big_grid_to_chunks(height_grid, wet_grid, temp_grid, debris_grid)
	#print('world_size =', big_grid.values())
	return world
	
@warning_ignore("unused_parameter")
func map_big_grid_to_chunks(big_grid:Dictionary,wet_grid:Dictionary, temp_grid:Dictionary, debris_grid:Dictionary) ->  Dictionary:
	var chunk_datas: Dictionary
	
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
			var moist:float = wet_grid[Vector2i(x,y)]
			var temp:float = temp_grid[Vector2i(x,y)]
			var debris:float = debris_grid[Vector2i(x,y)]
			
			if(moist > .5): 
				if(temp > .5):
					if(debris > .5):
						chunk.biome = ChunkData.Biome.EvilWetland
					else:
						chunk.biome = ChunkData.Biome.Wetland
				else:
					if(debris > .5):
						chunk.biome = ChunkData.Biome.Forest
					else:
						chunk.biome = ChunkData.Biome.Deepforest
			else:
				if(temp > .5):
					if(debris > .5):
						chunk.biome = ChunkData.Biome.Wasteland
					else:
						chunk.biome = ChunkData.Biome.Shrubland
				else:
					if(debris > .5):
						chunk.biome = ChunkData.Biome.Cityscape
					else:
						chunk.biome = ChunkData.Biome.Grassland
				
			
			var water : int  = randi_range(0, 2)
			var square_datas: Dictionary
			for i in chunk_size.x:
				for j in chunk_size.y:
					@warning_ignore("unused_variable")
					var total_x : int = (x * chunk_size.x) + i
					@warning_ignore("unused_variable")
					var total_y : int = (y * chunk_size.y) + j
					#print("total x : ", x, "total y: ",y, "elevation:", big_grid[Vector2i(total_x, total_y)])
					var square:SquareData = SquareData.new()
					#square.elevation = big_grid[Vector2i(total_x, total_y)]
					square.elevation = 0
					square.location_in_chunk = Vector2i(i,j)
					square.water_saturation = water
					if(j == 0):
						var object: ObjectData = ObjectData.new()
						object.object_id = "plant_tree_poplar"
						object.object_tags["age"] = i % 3
						square.object_data = [null, null, null, null]
						square.object_data[1] = object
						
					square_datas[Vector2i(i,j)] = square
					
			chunk.square_datas = square_datas
			chunk_datas[chunk.chunk_position] = chunk
	
	return chunk_datas 
	
## Generates on square-by-square basis
@warning_ignore("shadowed_global_identifier")
func generate_heights(seed: int) -> Dictionary:
	if !altitude_noise:
		altitude_noise = FastNoiseLite.new()
		altitude_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		altitude_noise.frequency = alt_freq
		altitude_noise.fractal_octaves = oct
		altitude_noise.fractal_lacunarity = lac
		altitude_noise.fractal_gain = gain

	altitude_noise.set_seed(seed)
	var total_tiles:Vector2 = chunk_size * num_chunks
	var grid :Dictionary = {}
	for x in total_tiles.x:
		for y in total_tiles.y:
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] =  abs(altitude_noise.get_noise_2d(x,y))*4
	
	return grid

## Generates on chunk-by-chunk basis- the rules handler will
## find the True Moisture Value of each square during runtime
@warning_ignore("shadowed_global_identifier")
func generate_moisture(seed: int) -> Dictionary:
	if !moisture_noise:
		moisture_noise = FastNoiseLite.new()
		moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		moisture_noise.frequency = alt_freq
		moisture_noise.fractal_octaves = oct
		moisture_noise.fractal_lacunarity = lac
		moisture_noise.fractal_gain = gain

	moisture_noise.set_seed(seed)
	var total_chunks:Vector2 = num_chunks
	var grid :Dictionary = {}
	for x in total_chunks.x:
		for y in total_chunks.y:
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] = moisture_noise.get_noise_2d(x,y)
	
	return grid

## Generates on chunk-by-chunk basis- used for determining biome
@warning_ignore("shadowed_global_identifier")
func generate_temperature(seed: int) -> Dictionary:
	if !temperature_noise:
		temperature_noise = FastNoiseLite.new()
		temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		temperature_noise.frequency = alt_freq
		temperature_noise.fractal_octaves = oct
		temperature_noise.fractal_lacunarity = lac
		temperature_noise.fractal_gain = gain

	temperature_noise.set_seed(seed)
	var total_chunks:Vector2 = num_chunks
	var grid :Dictionary = {}
	for x in total_chunks.x:
		for y in total_chunks.y:
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] =  temperature_noise.get_noise_2d(x,y)
	
	return grid

## Generates on chunk-by-chunk basis- used for determining biome
@warning_ignore("shadowed_global_identifier")
func generate_debris(seed: int) -> Dictionary:
	if !debris_noise:
		debris_noise = FastNoiseLite.new()
		debris_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		debris_noise.frequency = alt_freq
		debris_noise.fractal_octaves = oct
		debris_noise.fractal_lacunarity = lac
		debris_noise.fractal_gain = gain

	debris_noise.set_seed(seed)
	var total_chunks:Vector2 = num_chunks
	var grid :Dictionary = {}
	for x in total_chunks.x:
		for y in total_chunks.y:
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] =  debris_noise.get_noise_2d(x,y)
	
	return grid
