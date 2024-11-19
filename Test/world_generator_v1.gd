extends Node2D
class_name WorldGenerator

@export var world_manager: WorldManager
@export var terrain_rules_handler: TerrainRulesHandler

@export_group("WorldData properties")
@export var worldseed: int
@export var chunk_size: Vector2i = Vector2(50,50)
@export var num_chunks: Vector2i = Vector2(3,3)
@export var acceptable_objects: Array[ObjectData]

@export_group("Noise generation properties")
@export var noise_map : FastNoiseLite
@export var alt_freq : float = 0.005
@export var oct : int = 4
@export var lac : int = 2
@export var gain : float = 0.5
@export var amplitude : float = 1.0 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if worldseed == 0:
		worldseed = randi_range(1, 10000)
	if acceptable_objects == null:
		acceptable_objects = [ObjectData.new(), ObjectData.new("rock", null, {})]
		
	#print("loading")
	#var world:WorldData = ResourceLoader.load('res://Test/data/world_datas/BIGWORLD.tres')
	#print("loading coimplete")
	#world_manager.set_world_data(world)
	var world:WorldData = generate_world_based_on_vals()
	world_manager.world_data = world

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
	var big_grid:Dictionary = generate_shape()
	
	world.chunk_datas = map_big_grid_to_chunks(big_grid)
	#print('world_size =', big_grid.values())
	
	var save_result:Error = ResourceSaver.save(world, str('res://Test/data/world_datas/world', world.world_seed, '.tres'))
	if save_result != OK:
		print(save_result)
	print('time at end generation + save: ', Time.get_time_string_from_system())
	return world
	
func map_big_grid_to_chunks(big_grid:Dictionary) ->  Dictionary:
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
			chunk.biome = ChunkData.Biome.Forest
			
			var square_datas: Dictionary
			for i in chunk_size.x:
				for j in chunk_size.y:
					var total_x : int = (x * chunk_size.x) + i
					var total_y : int = (y * chunk_size.y) + j
					#print("total x : ", x, "total y: ",y, "elevation:", big_grid[Vector2i(total_x, total_y)])
					var square:SquareData = SquareData.new()
					square.elevation = big_grid[Vector2i(total_x, total_y)]
					square.location_in_chunk = Vector2i(i,j)
					square_datas[Vector2i(i,j)] = square
					
			chunk.square_datas = square_datas
			chunk_datas[chunk.chunk_position] = chunk
	
	return chunk_datas 

func generate_shape() -> Dictionary:
	if !noise_map:
		noise_map = FastNoiseLite.new()

		noise_map.noise_type = FastNoiseLite.TYPE_PERLIN
		#noise_map.frequency = alt_freq

		#noise_map.fractal_octaves = oct

		#noise_map.fractal_lacunarity = lac

		#noise_map.fractal_gain = gain

	noise_map.set_seed(worldseed)
	
	var total_tiles:Vector2 = chunk_size * num_chunks

	var grid :Dictionary = {}
	for x in total_tiles.x:
		for y in total_tiles.y:
			var rand:float = abs(noise_map.get_noise_2d(x,y))
			rand = rand*4
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] = rand
	
	return grid
