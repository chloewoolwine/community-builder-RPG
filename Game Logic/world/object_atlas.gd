extends Node2D
class_name ObjectAtlas

@onready var world_manager: WorldManager = $"../.."

signal plant_placed(plant: GenericPlant)
signal new_object_placed(object: ObjectData)

# GODOT SORT HEIRARCHY 
#  CanvasLayer > overrules > z_index > overrules > Ysort > overrules > scene tree hierarchy 
#  Ysort on the other hand affects only affects the direct children of a Ysort node, 
#  not it's grand children. You can therefore use the scene tree hierarchy to sort 
#  the Sprites of your character how you like. 


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

#this is unloaded when the chunks are unloaded
var loaded_objects: Dictionary

# object id: plant_tree_poplar, tags: "age": "100" 

# all objects live in the scene Individually- key is the object data
# they keep track of their own object datas
var live_objects: Dictionary

func translate_object(object_datas: Array[ObjectData],overall_position: Vector2, square: SquareData) -> void: 
	if object_datas == null:
		return
	if object_datas.size() < 2: # floors are not really objects. it's a lie.
		return 
	for x in range(1, object_datas.size()):
		var object_data := object_datas[x]
		if object_data == null:
			continue
		if object_data.object_id == Constants.POINTER:
			pass
		else: 
			_parse_and_place(object_data, overall_position, square)

func remove_objects(object_datas: Array[ObjectData], pos: Location) -> Array[ObjectData]: 
	for x in range(1, object_datas.size()):
		var object_data := object_datas[x]
		if object_data != null && object_data.object_id != Constants.POINTER:
			if object_data.object_id != Constants.POINTER && object_data not in live_objects.keys():
				push_warning("Object_id: ", object_data.object_id, " expected to be in live objects, not found at loc ", pos)
				continue 
			var object: Node2D = live_objects[object_data]
			if object_data == null:
				# object probably killed itself
				live_objects.erase(object_data)
				object_datas[x] = null # erase the object data because it killed itself
			else:
				object.queue_free() # TODO: specific objects might have some stuff to do? not sure!
			live_objects.erase(object_data)
	return object_datas
	
func place_object(object_data: ObjectData, overall_position: Vector2, square: SquareData)-> void:
	if object_data.object_id != "":
		_parse_and_place(object_data, overall_position, square)
		new_object_placed.emit(object_data)

func _parse_and_place(object_data: ObjectData, overall_position: Vector2, square: SquareData) -> Node2D: 
	if object_data != null:
		if object_data.object_id != "":
			#print("new object, location: ", overall_position, "   ", object_data.chunk, " ", object_data.position)
			var split := object_data.object_id.split("_")
			var path := object_scene_location + split[0] + "/" + split[1] + "/" + split[2] + ".tscn"
			if path not in loaded_objects.keys():
				loaded_objects[path] = load(path) # blocking action - TODO, refractor to be multithreaded
				#https://docs.godotengine.org/en/latest/tutorials/io/background_loading.html
			var object:Node2D = loaded_objects[path].instantiate()
			object.position = overall_position
			object.object_data = object_data
			# TODO: this is shit!! fix when refractoring to be more component based
			if object is GenericPlant or object is GenericWall or object.is_in_group(&"removable"):
				if object.has_signal(&"object_removed"):
					object.object_removed.connect(world_manager.destroy_object)
				else:
					var child:Node = object.find_child("SimpleCollectable")
					if child != null:
						child.object_removed.connect(world_manager.destroy_object)
			var hitbox: Node2D = find_child("InteractionHitbox", false)
			if hitbox: 
				hitbox.current_elevation = square.elevation
			live_objects[object_data] = object
			add_child(object)
			if split[0] == "plant":
				object.square_data = square
				plant_placed.emit(object)
			return object
		else: 
			print("empty object id?")
	return null

func pop_away_object(object_data: ObjectData) -> void:
	@warning_ignore("untyped_declaration")
	var object = live_objects[object_data]
	if object == null:
		print("Warning! tried to pop away object that was not live, doing nothing about it")
		return
	#TODO: object needs to go into the players inventory or spawn new
	object.queue_free()
	live_objects.erase(object_data)
