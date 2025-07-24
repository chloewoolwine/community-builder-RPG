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
	#sand/dirt/rocks
	do_squaretype_stuff(world)
	world.chunk_datas[Vector2i(-1, -1)] = SPAWN_CHUNK.chunk_datas[Vector2i(-1,-1)]
	#run a single natural water pass
	print("running water calc")
	EnvironmentLogic.run_water_calc(world, world.chunk_datas.keys())
	
	print("putting down plants")
	#run plant pass
	put_down_plants(world)
	
	return world
	
func put_down_plants(world_data: WorldData) -> void:
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
								var m:int
								if object.object_id == "plant_wild_reed:":
									m = 3
								else:
									m = 0
								poof_grass(Location.new(Vector2i(i,j), Vector2i(x-modx, y-mody)), object.object_id, m, world_data.chunk_datas)
							else:
								square_data.object_data = [null, object, null]
							
								
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
	if depth == 0:
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
	
	print("water pass")
	for x in num_chunks.x:
		for y in num_chunks.y:
			var chunk:ChunkData = chunk_datas[Vector2i(x - modx, y - mody)]
			#if x == q_x and y == q_y:
				#continue
			for i in chunk_size.x:
				for j in chunk_size.y:
					var square : SquareData= chunk.square_datas[Vector2i(i,j)]
					var n1 :int = (x*32)+i
					var n2:int = (y*32)+j
					var val: float= abs(moisture_noise.get_noise_2d(n1, n2))
					
					#get rid of single water tiles
					var has_neighbor: bool = true
					for w in range(-1, 2, 1):
						for v in range(-1, 2, 1):
							if !(w == 0 && v == 0):
								var neighbor: float= abs(moisture_noise.get_noise_2d(n1 + w, n2 + v))
								if neighbor > .7:
									has_neighbor = true
					#print(val)
					if val > .7 && has_neighbor: 
						square.water_saturation = 4
						if randf() > .5:
							var matrix := Location.new(square.location_in_chunk, chunk.chunk_position).get_neighbor_matrix()
							for item in matrix:
								if item.chunk in chunk_datas.keys():
									var s:SquareData = chunk_datas[item.chunk].square_datas[item.position]
									s.type = SquareData.SquareType.Sand
					if val > .9 && has_neighbor: 
						square.water_saturation = 5
	
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
			#if chunk.biome != ChunkData.Biome.Wetland:
			# everything is a forest, for now 
			chunk.biome = chunk.Biome.Forest
			
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
					square.water_saturation = 1
					square_datas[Vector2i(i,j)] = square
					square.type = SquareData.SquareType.Grass
					#if(j == 0):
						#var object: ObjectData = ObjectData.new()
						#object.object_id = "plant_tree_poplar"
						#object.object_tags["age"] =  15000
						#square.object_data = [null, null, null]
						#square.object_data[1] = object
						
					
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
	#if !moisture_noise:
		#moisture_noise = FastNoiseLite.new()
		#moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
		#moisture_noise.frequency = alt_freq
		#moisture_noise.fractal_octaves = oct
		#moisture_noise.fractal_lacunarity = lac
		#moisture_noise.fractal_gain = gain

	var other_noise := get_new_noise(123)
	other_noise.set_seed(seed)
	var total_chunks:Vector2 = num_chunks
	var grid :Dictionary = {}
	for x in total_chunks.x:
		for y in total_chunks.y:
			#this could, theoretically, be 4. which is out of range. ah well
			@warning_ignore("narrowing_conversion")
			grid[Vector2i(x,y)] = other_noise.get_noise_2d(x,y)
	
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
			#grid[Vector2i(x,y)] =  debris_noise.get_noise_2d(x,y)
			grid[Vector2i(x,y)] =  0
	
	return grid

@warning_ignore("shadowed_global_identifier")
func get_new_noise(seed: int) -> FastNoiseLite:
	var new_noise := FastNoiseLite.new()
	new_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	new_noise.frequency = alt_freq
	new_noise.fractal_octaves = oct
	new_noise.fractal_lacunarity = lac
	new_noise.fractal_gain = gain
	new_noise.seed = seed 
	return new_noise
