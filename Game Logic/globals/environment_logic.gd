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

#this is the "REAL" global position- y offset needs to be ON LOC
static func get_real_pos_object(loc: Location, elevation: int) -> Vector2:
	##((pos * 64) + (chunk * 64 * 32)) + Vector2i(0, layer.elevation*-32) + Vector2i(32, 32)
	var world_pos := (loc.chunk * Constants.CHUNK_SIZE) + loc.position
	@warning_ignore("integer_division")
	## 		tile position 			+		elevation offset 							   +		middle of tile
	return world_pos * Constants.TILE_SIZE + Vector2i(0, elevation*-(Constants.TILE_SIZE/2)) + Vector2i((Constants.TILE_SIZE/2), (Constants.TILE_SIZE/2))

static func get_base_pos_object(loc: Location) -> Vector2:
	var world_pos := (loc.chunk * Constants.CHUNK_SIZE) + loc.position
	@warning_ignore("integer_division")
	return world_pos * Constants.TILE_SIZE + Vector2i((Constants.TILE_SIZE/2), (Constants.TILE_SIZE/2))

#returns null if requested square is out of bounds
static func get_square(world_data: WorldData, loc: Location) -> SquareData:
	if loc == null:
		push_error("location is null in get square :c")
	#TODO: optimize this! this gets called all of the time
	if loc.chunk not in world_data.chunk_datas:
		return null
	return world_data.chunk_datas[loc.chunk].square_datas[loc.position]

static func place_object_data(world_data: WorldData, loc: Location, name: StringName, age:int = -1, clear:bool = false) -> ObjectData:
	var object:= DatabaseManager.fetch_object_data(name)
	var square:= get_square(world_data, loc)
	if !object_is_valid_to_place(clear, object.additive, square, square.elevation):
		return null
	var locs:Array[Location] = _get_locs_of_size(object.size, loc)
	for new_loc in locs:
		if !object_is_valid_to_place(clear, object.additive, get_square(world_data, new_loc), square.elevation):
			return null
	
	#if we're still here, we are Valid! 
	var new_object:ObjectData = object.duplicate(true)
	#print("palcing object: ", new_object.object_id)
	new_object.object_tags["age"] = age
	new_object.last_loaded_minute = age
	new_object.position = loc.position
	new_object.chunk = loc.chunk
	if square.object_data == null || square.object_data.is_empty():
		square.object_data = [null, null, null]
	if square.object_data[1] != null && !new_object.additive:
		remove_object(world_data, loc)
	if new_object.additive:
		square.object_data.append(new_object)
	else:
		square.object_data[1] = new_object
	if locs.size() > 0:
		new_object.object_tags[Constants.POINTER] = locs
		_fill_with_pointers(world_data, loc, new_object.size)

	return new_object

static func _fill_with_pointers(world_data:WorldData, loc: Location, size: Vector2i) -> void: 
	var locs := _get_locs_of_size(size, loc)
	
#	print("location: ", loc, " pointer locs: ", locs)
	for new_loc in locs:
		if new_loc.equals(loc):
			continue
		var pointer:ObjectData = ObjectData.new()
		pointer.object_id = Constants.POINTER
		pointer.object_tags[Constants.ORIGIN] = loc
		pointer.position = new_loc.position
		pointer.chunk = new_loc.chunk
		var square:= get_square(world_data, new_loc)
		if square == null: #out of bounds, probably doesn't matter ? 
			continue 
		if square.object_data == null || square.object_data.is_empty():
			square.object_data = [null, null, null]
		square.object_data[1] = pointer
		pass

static func _get_locs_of_size(size: Vector2i, loc: Location) -> Array[Location]:
	var locs:Array[Location] = []
	match size: #yeah i cant think of a better way to do this :/ theres probably something with arrays but im stupid rn
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
			locs = (loc.get_neighbor_matrix())
	return locs

static func object_is_valid_to_place(clear:bool, additive:bool, square:SquareData, ele_targ: int) -> bool:
	if square == null:
		return false
	if square.elevation != ele_targ:
		return false
	if square.object_data.size() > 1 && square.object_data[1] != null: # if there is something there
		if clear: 
			return true
		elif additive:
			return true
		else:
			return false
	return true

#NOT intended to give loot or anything else. this is JUST for removing objects & its pointers from a loc
static func remove_object(world_data:WorldData, loc: Location) -> void:
	var square := get_square(world_data, loc)
	if square.object_data == null || square.object_data[1] == null:
		return
	var object:ObjectData = square.object_data[1]
	if object.object_id == Constants.POINTER:
		square = get_square(world_data, object.object_tags[Constants.ORIGIN])
		object = square.object_data[1]
		if object == null:
			#fuck
			get_square(world_data, loc).object_data[1] = null
			push_warning("Stray pointer :c")
			return
	var locs:Array = object.object_tags.get(Constants.POINTER, [])
	for x:Location in locs:
		var o_square := get_square(world_data, x)
		if square.object_data == null || square.object_data[1] == null:
			continue
		o_square.object_data[1] = null
	square.object_data[1] = null

static func has_objects(square: SquareData) -> bool:
	if square.object_data == null:
		return false
	if square.object_data.is_empty():
		return false
	for obj in square.object_data:
		if obj != null:
			return true
	return false

static func ele_y_offset(elevation: int) -> int:
	return elevation * Constants.ELEVATION_Y_OFFSET
