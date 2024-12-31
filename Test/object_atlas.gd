extends Node2D
class_name ObjectAtlas

signal plant_placed(plant: GenericPlant)
signal new_object_placed(object: ObjectData)

# every object type: 
# plant
#  - plants should be able to have more than one sprite
#  - usually come from seeds
#  - trees and plants are going to have to be different- trees will always need more than one sprit
# build (walls, roofs, etc.)
#  - THIS is going to be difficult. 
#  - maybe seperate objects until the walls are combined- then they will conglomerate into a BuildingData?
#  - want to bust down exterior wall? remove the roof first
#  - contains list of walls and floors, rooms are determined at runtime
#  - decor is it's own object? 
#  - how to hang stuff on walls??? windows, doors? 
# craftings/ chests/ gui objects
#  - should just have CraftingComponent 
#  - get to "just add a chest component" for usecase
# floors (special handling) 
#  - handled in tileset while parsing square data
# These can sometimes overlap 

# maybe if i make modding tools, i can have a script that creates these scenes in the 
# right spots? then i wouldn't have to refracro this that much 
const GENERIC_BUILDING = preload("res://Scenes/object/build/generic_building.tscn")
const object_scene_location: String = "res://Scenes/object/"

## WARNING! WARNING! Probably need to make some kind of cleanup script that 
## runs periodically in order to unload what's loaded in this dictionary- 
## or else long play sessions will have memoryleak esque problems 
## Contains object_data -> packed scenes
var loaded_objects: Dictionary

# object id: plant_tree_poplar, tags: "age": "100" 

# all objects live in the scene Individually- key is the object data
# they keep track of their own object datas
var live_objects: Dictionary

# segregates buildings into this dictionary for ease of checking 
var live_buildings: Dictionary

func translate_object(object_datas: Array[ObjectData],overall_position: Vector2, elevation: int) -> void: 
	if object_datas == null:
		return
	if object_datas.size() < 2: # floors are not really objects. it's a lie.
		return 
	for x in range(1, object_datas.size()):
		var object_data := object_datas[x]
		if object_data != null:
			if object_data.object_id != "":
				var split := object_data.object_id.split("_")
				var path := object_scene_location + split[0] + "/" + split[1] + "/" + split[2] + ".tscn"
				if path[1] != "wall": # this isn't going to work for singletons. TODO: fix that 
					if path not in loaded_objects.keys():
						loaded_objects[path] = load(path) # blocking action - TODO, refractor to be multithreaded
						#https://docs.godotengine.org/en/latest/tutorials/io/background_loading.html
					var object:Node2D = loaded_objects[path].instantiate()
					object.position = overall_position
					if split[0] == "plant":
						object.object_data = object_data
					var hitbox: Node2D = find_child("InteractionHitbox", false)
					if hitbox: 
						hitbox.current_elevation = elevation
					live_objects[object_data] = object
					add_child(object)
					if split[0] == "plant":
						plant_placed.emit(object)
			else: 
				print("empty object id?")

func build_building(build_data: BuildData, elevation: int) -> void:
	print("building building")
	if is_building_live(build_data):
		return
	var building_object := GENERIC_BUILDING.instantiate()
	building_object.build_data = build_data
	building_object.roof = build_data.roof
	live_buildings[build_data] = building_object
	for wall_data in build_data.walls: 
		var split := wall_data.object_id.split("_")
		var path := object_scene_location + split[0] + "/" + split[1] + "/" + split[2] + ".tscn"
		if path not in loaded_objects.keys():
			loaded_objects[path] = load(path) 
		var object:GenericWall = loaded_objects[path].instantiate()
		print("wall data: ", wall_data)
		object.object_data = wall_data
		object.object_id = wall_data.object_id
		var hitbox: Node2D = find_child("InteractionHitbox", false)
		if hitbox: 
			hitbox.current_elevation = elevation
		# this might damn well be wrong
		object.global_position = wall_data.chunk * 64 * 32 + (wall_data.position * 64)
		building_object.add_child(object)
		#set wall to object data 
	add_child(building_object)
	
## the same building in different chunks might load as different build_datas
## check by comparing walls 
func is_building_live(build_data: BuildData) -> bool: 
	for live:BuildData in live_buildings.keys():
		if live.chunk == build_data.chunk && live.position == build_data.position:
			return true
	return false

func remove_objects(object_datas: Array[ObjectData]) -> Array[ObjectData]: 
	for x in range(1, object_datas.size()):
		var object_data := object_datas[x]
		if object_data != null:
			if object_data not in live_objects.keys():
				push_warning("Object_id: ", object_data.object_id, " expected to be in live objects, not found")
				continue 
			var object: Node2D = live_objects[object_data]
			if object_data == null:
				# object probably killed itself
				live_objects.erase(object_data)
				object_datas[x] = null # erase the object data because it killed itself
			object.queue_free() # TODO: specific objects might have some stuff to do? not sure!
			live_objects.erase(object_data)
	return object_datas
	
func new_building(build_data: BuildData, build: GenericBuilding) -> void:
	live_buildings[build_data] = build

func remove_building(build_data: BuildData) -> void:
	live_buildings[build_data] = null
	
func place_object(object_data: ObjectData, overall_position: Vector2, elevation: int)-> void:
	if object_data.object_id != "":
		var split := object_data.object_id.split("_")
		var path := object_scene_location + split[0] + "/" + split[1] + "/" + split[2] + ".tscn" 
		if path not in loaded_objects.keys():
			loaded_objects[path] = load(path) 
		var object:Node2D = loaded_objects[path].instantiate()
		object.object_data = object_data
		object.object_id = object_data.object_id
		var hitbox: Node2D = find_child("InteractionHitbox", false)
		if hitbox: 
			hitbox.current_elevation = elevation
		object.global_position = overall_position
		live_objects[object_data] = object
		add_child(object)
		new_object_placed.emit(object_data)
		if object is GenericPlant:
			plant_placed.emit(object)

func pop_away_object(object_data: ObjectData) -> void:
	@warning_ignore("untyped_declaration")
	var object = live_objects[object_data]
	if object == null:
		print("Warning! tried to pop away object that was not live, doing nothing about it")
		return
