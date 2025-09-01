class_name EnvironmentLogic

static func run_daily(world: WorldData, day:int, hour:int, minute:int, _is_raining: bool = false, do_plants:bool = true) -> void:
	var all_chunks := world.chunk_datas
	@warning_ignore("untyped_declaration")
	for chunk_loc in all_chunks:
		var chunk_data:ChunkData = all_chunks[chunk_loc]
		for square_loc:Vector2i in chunk_data.square_datas.keys():
			var square_data:SquareData = chunk_data.square_datas[square_loc]
			#1 is just supposed to be the ambient moisture for the forest/farm, not everywhere
			#that is for way later tho
			if square_data.water_saturation > 1 && square_data.water_saturation < 4 && do_plants:
				check_plant_growth(square_data, day, hour, minute)
				square_data.water_saturation -= 1 #dry everything by 1
	run_water_calc(world, all_chunks.keys()) #rewet 

static func check_plant_growth(square: SquareData, day:int, hour:int, minute:int) -> void: 
	var current_minute := (day*1440) + (hour*60) + minute # i really need to make a constants file
	for object in square.object_data:
		# the plant was not loaded
		if object != null && object.object_id.contains("plant") && object.last_loaded_minute < current_minute -1:
			#TODO: plants need to propagate and grow while unloaded
			pass

static func run_water_calc(world: WorldData, chunks_around:Array, _is_raining: bool = false) -> void:
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
	var all_chunks := world.chunk_datas
	var all_water : Array[Location]
	#print(world_manager._world_data.chunk_datas.keys())
	for chunk_loc:Vector2i in chunks_around:
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
			
			#temp-probably remove later
			if square_data.water_saturation == 0:
				square_data.water_saturation = 1
	
	var tier3: Array[Location]
	var tier2: Array[Location]
	for water_loc in all_water:
		tier3.append_array(_get_most_wet(water_loc))
		tier2.append_array(_get_circle(world, water_loc, Constants.water_source_saturation_width)) 
	for loc in tier2:
		if loc.chunk in all_chunks:
			var square_data:SquareData = all_chunks[loc.chunk].square_datas[loc.position]
			if square_data.water_saturation < 2:
				square_data.water_saturation = 2
	for loc in tier3:
		if loc.chunk in all_chunks:
			var square_data:SquareData = all_chunks[loc.chunk].square_datas[loc.position]
			if square_data.water_saturation < 3:
				square_data.water_saturation = 3
	#TODO: water falls farther in lower elevations

static func _get_circle(world: WorldData, center: Location, radius: int) -> Array[Location]:
	var chunk_size := world.chunk_size.x
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

static func _get_most_wet(water_source:Location) -> Array[Location]:
	return [water_source.get_location(Vector2i.UP), water_source.get_location(Vector2i.DOWN), 
	water_source.get_location(Vector2i.LEFT), water_source.get_location(Vector2i.RIGHT),
	water_source.get_location(Vector2i.UP + Vector2i.LEFT),
	water_source.get_location(Vector2i.UP + Vector2i.RIGHT),
	water_source.get_location(Vector2i.DOWN + Vector2i.LEFT),
	water_source.get_location(Vector2i.DOWN + Vector2i.RIGHT)]

static func get_real_pos_object(loc: Location, elevation: int) -> Vector2:
	##((pos * 64) + (chunk * 64 * 32)) + Vector2i(0, layer.elevation*-32) + Vector2i(32, 32)
	var world_pos := (loc.chunk * Constants.CHUNK_SIZE) + loc.position
	@warning_ignore("integer_division")
	return world_pos * Constants.TILE_SIZE + Vector2i(0, elevation*-(Constants.TILE_SIZE/2)) + Vector2i((Constants.TILE_SIZE/2), (Constants.TILE_SIZE/2))

static func get_square(world_data: WorldData, loc: Location) -> SquareData:
	return world_data.chunk_datas[loc.chunk].square_datas[loc.position]

static func place_object_data(world_data: WorldData, loc: Location, name: StringName, age:int = -1, clear:bool = false) -> bool:
	var object:= DatabaseManager.fetch_object_data(name)
	var square:= get_square(world_data, loc)
	if !object_is_valid_to_place(clear, object.additive, square):
		return false
	var locs:Array[Location]
	if !clear:
		match object.size: #yeah i cant think of a better way to do this :/ theres probably something with arrays but im stupid rn
			Vector2i(1,1):
				pass
			Vector2i(1,2):
				locs.append(loc.get_location(Vector2i(0,1)))
			Vector2i(2,1):
				locs.append(loc.get_location(Vector2i(1,0)))
			Vector2i(2,2):
				locs.append(loc.get_location(Vector2i(1,0)))
				locs.append(loc.get_location(Vector2i(0,1)))
				locs.append(loc.get_location(Vector2i(1,1)))
			Vector2i(3,3):
				for x in range(-1, 1):
					for y in range(-1, 1):
						locs.append(loc.get_location(Vector2i(x,y)))
			_:
				return false # give up !
	
	for new_loc in locs:
		if !object_is_valid_to_place(clear, object.additive, get_square(world_data, new_loc)):
			return false
			
	#if we're still here, we are Valid! 
	var new_object:ObjectData = object.duplicate(true)
	print("palcing object: ", new_object.object_id)
	new_object.object_tags["age"] = age
	new_object.last_loaded_minute = age
	new_object.position = loc.position
	new_object.chunk = loc.chunk
	if square.object_data == null || square.object_data.is_empty():
		square.object_data = [null, null, null]
	if new_object.additive:
		square.object_data.append(new_object)
	else:
		square.object_data[1] = new_object
	
	return true

static func _fill_with_pointers(world_data, loc: Location, size: Vector2i) -> void: 
	var pointer:ObjectDataPointer= DatabaseManager.fetch_object_data(&"object_data_pointer").duplicate(true)
	pointer.originating_square = loc
	var locs:Array[Location]
	match size:
		Vector2i(1,1):
			pass
		Vector2i(1,2):
			locs.append(loc.get_location(Vector2i(0,1)))
		Vector2i(2,1):
			locs.append(loc.get_location(Vector2i(1,0)))
		Vector2i(2,2):
			locs.append(loc.get_location(Vector2i(1,0)))
			locs.append(loc.get_location(Vector2i(0,1)))
			locs.append(loc.get_location(Vector2i(1,1)))
		Vector2i(3,3):
			for x in range(-1, 1):
				for y in range(-1, 1):
					locs.append(loc.get_location(Vector2i(x,y)))
		_:
			return
	for new_loc in locs:
		var copy:= pointer.duplicate(true)
		var square:= get_square(world_data, new_loc)
		if square.object_data == null || square.object_data.is_empty():
			square.object_data = [null, null, null]
		square.object_data[1] = copy

static func object_is_valid_to_place(clear:bool, additive:bool, square:SquareData) -> bool:
	if square.object_data.size() > 1 && square.object_data[1] != null: # if there is something there
		if clear: 
			return true
		elif additive:
			return true
		else:
			return false
	return true
