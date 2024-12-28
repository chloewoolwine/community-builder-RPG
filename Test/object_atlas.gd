extends Node2D
class_name ObjectAtlas

signal plant_placed(plant: GenericPlant)

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

const object_scene_location: String = "res://Scenes/object/"

## WARNING! WARNING! Probably need to make some kind of cleanup script that 
## runs periodically in order to unload what's loaded in this dictionary- 
## or else long play sessions will have memoryleak esque problems 
var loaded_objects: Dictionary

# object id: plant_tree_poplar, tags: "age": "100" 

# all objects live in the scene Individually- key is the object data
# TODO: find a way for objects to tell ObjectAtlas that they need updating
# probably use a standard ObjectStateChange signal linked to the atlas
# and a reverse dictionary mapping the nodes to object_datas 
# or... just have them reference their own object datas? 
var live_objects: Dictionary

func translate_object(object_datas: Dictionary,overall_position: Vector2) -> void: 
	if object_datas == null:
		return
	for x:int in object_datas.keys():
		var object_data: ObjectData= object_datas[x]
		if object_data != null && x != 0:
			if object_data.object_id != "":
				var split := object_data.object_id.split("_")
				var path := object_scene_location + split[0] + "/" + split[1] + "/" + split[2] + ".tscn"
				if path not in loaded_objects.keys():
					loaded_objects[path] = load(path) # blocking action - TODO, refractor to be multithreaded
					#https://docs.godotengine.org/en/latest/tutorials/io/background_loading.html
				var object:Node2D = loaded_objects[path].instantiate()
				object.position = overall_position
				if split[0] == "plant":
					object.object_data = object_data
					plant_placed.emit(object)
				live_objects[object_data] = object
				add_child(object)
			else: 
				print("empty object id?")
	
func remove_objects(object_datas: Dictionary) ->Dictionary: 
	for x in object_datas.keys():
		var object_data:ObjectData = object_datas[x]
		if object_data != null && x != 0:
			var object: Node2D = live_objects[object_data]
			if object == null:
				# object probably killed itself
				live_objects.erase(object_data)
				object_datas.erase(x) # erase the object data because it killed itself
			object.queue_free() # TODO: specific objects might have some stuff to do? not sure!
			live_objects.erase(object_data)
	return object_datas

func pop_away_object(object_data: ObjectData) -> void:
	@warning_ignore("untyped_declaration")
	var object = live_objects[object_data]
	if object == null:
		print("Warning! tried to pop away object that was not live, doing nothing about it")
		return
