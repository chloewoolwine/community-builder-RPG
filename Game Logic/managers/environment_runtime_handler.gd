extends Node2D
class_name EnvironmentRuntime

@onready var world_manager: WorldManager = $".."
@onready var trh: TerrainRulesHandler = $"../TerrainRulesHandler"

var is_raining: bool

func _ready() -> void:
	pass
	
func run_daily(day:int, hour:int, minute:int) -> void:
	var all_chunks := world_manager._world_data.chunk_datas
	@warning_ignore("untyped_declaration")
	for chunk_loc in all_chunks:
		var chunk_data:ChunkData = all_chunks[chunk_loc]
		for square_loc:Vector2i in chunk_data.square_datas.keys():
			var square_data:SquareData = chunk_data.square_datas[square_loc]
			if square_data.water_saturation > 0:
				check_plant_growth(square_data, day, hour, minute)
				square_data.water_saturation -= 1 #dry everything by 1
	run_water_calc(all_chunks.keys()) #rewet 

func check_plant_growth(square: SquareData, day:int, hour:int, minute:int) -> void: 
	var current_minute := (day*1440) + (hour*60) + minute # i really need to make a constants file
	for object in square.object_data:
		# the plant was not loaded
		if object.object_id.contains("plant") && object.last_loaded_minute < current_minute -1:
			#TODO: plants need to propagate and grow while unloaded
			pass

func run_water_calc(chunks_around:Array[Vector2i]) -> void:
	# water rules! (for base biome)
	# - water nearby sources radiate out from tile
	# - closest - 3 
	# - 2-3 tiles ** - 2 
	
	# ** - this will reset as you go down hill. 
	# meaning, a pond on level 3 can potentially water 6 tiles in every direction going downhill
	
	# we start with 1
	# a player can only water to 2. 
	# 3 NEEDS a water source 
	# plants will not complain if they have more moisture than needed
	# crops - need 2 
	# wild plants - most need 1, rarer plants will need more 
	
	#certain structures will Suck Moisture, but we can get to that later
	var all_chunks := world_manager._world_data.chunk_datas
	var all_water : Array[Location]
	#print(world_manager._world_data.chunk_datas.keys())
	for chunk_loc in chunks_around:
		var chunk_data:ChunkData 
		if chunk_loc in all_chunks.keys():
			chunk_data = all_chunks[chunk_loc]
		else: # this is if the chunk doesn't exist completely- shouldn't hit when i have buffer chunks existing
			continue
		for square_loc:Vector2i in chunk_data.square_datas.keys():
			var square_data:SquareData = chunk_data.square_datas[square_loc]
			if square_data.water_saturation > 3:
				all_water.append(Location.new(square_loc, chunk_loc))
				#print("water at: ", square_loc, chunk_loc)
	
	var tier3: Array[Location]
	var tier2: Array[Location]
	for water_loc in all_water:
		tier3.append_array(_get_most_wet(water_loc))
		tier2.append_array(_get_circle(water_loc, 4)) #~ i need a constants file~
	
	for loc in tier2:
		var square_data:SquareData = all_chunks[loc.chunk].square_datas[loc.position]
		square_data.water_saturation = 2
	for loc in tier3:
		var square_data:SquareData = all_chunks[loc.chunk].square_datas[loc.position]
		square_data.water_saturation = 3

func _get_circle(center: Location, radius: int) -> Array[Location]:
	var chunk_size := world_manager._world_data.chunk_size.x
	var arr : Array[Location]
	var total_loc: Vector2i = center.get_world_coordinates(chunk_size)
	for x in range(total_loc.x - radius, total_loc.x+1):
		for y in range(total_loc.y - radius, total_loc.y+1):
			if (pow(x - total_loc.x, 2) + pow(y - total_loc.y, 2) <= pow(radius, 2)):
				@warning_ignore("untyped_declaration")
				var xSym = total_loc.x - (x - total_loc.x)
				@warning_ignore("untyped_declaration")
				var ySym = total_loc.y - (y - total_loc.y)
				if !(x == total_loc.x && y == total_loc.y):
					arr.append_array([Location.get_location_from_world(Vector2i(x,y), chunk_size), 
					Location.get_location_from_world(Vector2i(x,ySym), chunk_size), 
					Location.get_location_from_world(Vector2i(xSym,y), chunk_size),
					Location.get_location_from_world(Vector2i(xSym,ySym), chunk_size)])
					#print("appended locations: ", arr)
	return arr

func _get_most_wet(water_source:Location) -> Array[Location]:
	return [water_source.get_location(Vector2i.UP), water_source.get_location(Vector2i.DOWN), 
	water_source.get_location(Vector2i.LEFT), water_source.get_location(Vector2i.RIGHT),
	water_source.get_location(Vector2i.UP + Vector2i.LEFT),
	water_source.get_location(Vector2i.UP + Vector2i.RIGHT),
	water_source.get_location(Vector2i.DOWN + Vector2i.LEFT),
	water_source.get_location(Vector2i.DOWN + Vector2i.RIGHT)]
