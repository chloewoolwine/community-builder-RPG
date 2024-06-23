extends Node
class_name SaverLoader

var prefix = "user://"
var save_name: String

#*ALL* this node worries about is getting whatever is in these three datas into a file
#and then getting them out of a file and into the loaded versions :D
@export var player : PlayerData
@export var story : StoryData #contains story flags, time of day, weather, environment status, etc..
@export var world : WorldData #data about maps, contains chunk data, which contain entities

var loaded_player : PlayerData
var loaded_story : StoryData
var loaded_world : WorldData

func create_current_filename() -> String:
	save_name = player.name + Time.get_date_string_from_system() + ".dat"
	return save_name

func save() -> bool:
	if !check_for_vars():
		return false
		
	create_current_filename()
	var file = FileAccess.open(prefix + save_name, FileAccess.WRITE)
	
	file.store_var(create_player_dict())
	file.store_var(create_story_dict())
	file.store_var(create_world_dict())
	file.close()
		
	return true
	
func create_player_dict() -> Dictionary:
	var player_dict = {}
	
	var player_script = player.get_script()
	
	#get all properties in the player script- in case i add more later :D 
	for property in player_script.get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			player_dict[property.name] = player.get(property.name)
	
	player_dict["inventory"] = create_inventory_dict(player.inventory)
	return player_dict
	
func create_story_dict() -> Dictionary:
	var story_dict = {}
	
	var story_script = story.get_script()
	
	#get all properties in the player script- WHEN i add more later >:D
	for property in story_script.get_script_property_list():
		if property.name.right(3) != ".gd":
			story_dict[property.name] = story.get(property.name)

	return story_dict

func create_world_dict() -> Dictionary:
	var world_dict = {}
	
	#store general world data
	
	world_dict.world_seed = world.world_seed
	world_dict.world_size = world.world_size
	world_dict.chunk_size = world.chunk_size

	var chunks_array = []
	for chunk_data in world.chunk_datas:
		chunks_array.append(create_chunk_dict(chunk_data))
	#print(chunks_array)
	world_dict.chunk_datas = chunks_array
	
	return world_dict
	
func create_chunk_dict(chunk_data: ChunkData) -> Dictionary:
	var chunk_dict = {}
	
	chunk_dict.chunk_size = chunk_data.chunk_size
	chunk_dict.chunk_position = chunk_data.chunk_position
	chunk_dict.biome = chunk_data.biome
	if chunk_data.entities:
		chunk_dict.entities = create_entity_dict(chunk_data.entities)
	
	var square_array = []
	for square_data in chunk_data.square_datas:
		square_array.append(create_square_dict(square_data))
	chunk_dict.square_datas = square_array
	
	return chunk_dict
	
func create_square_dict(square_data: SquareData) -> Dictionary:
	var square_dict = {}
	
	for property in square_data.get_script().get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			square_dict[property.name] = square_data.get(property.name)
	
		if square_data.inventory:
			square_dict["inventory"] = create_inventory_dict(square_data.inventory)
			
	return square_dict

#TODO: i have no idea if this actually works. 
#good luck, me in 10 weeks ! :D 
func create_entity_dict(entity_datas: Array[EntityData]) -> Dictionary:
	var all_entities_dict = {}
	for entity_data in entity_datas:
		var entity_dict = {}
		for property in entity_data.get_script().get_script_property_list():
			if property.name.right(3) != ".gd" && property.name != "inventory":
				entity_dict[property.name] = entity_data.get(property.name)
		
		if entity_data.inventory:
			entity_dict["inventory"] = create_inventory_dict(entity_data.inventory)
				
				
		all_entities_dict[entity_data.unique_id] = entity_dict
	
	return all_entities_dict
	
func create_inventory_dict(inventory_data: InventoryData):
	var inventory_dict = {}
	for i in inventory_data.slot_datas.size():
		var slot = inventory_data.slot_datas[i]
		if slot:
			inventory_dict[i] = [slot.quantity, slot.item_data.get_path().get_file().left(-5)]
		else: 
			inventory_dict[i] = []
		
	return inventory_dict
	
func check_for_vars() -> bool:
	#if !world:
	#	push_error("attempted to save without valid world data")
	#	return false
	if !player:
		push_error("attempted to save without valid player data")
		return false
	if !story:
		push_error("attempted to save without valid story data")
		return false
	return true

func load(save_name) -> bool:
	if FileAccess.file_exists(prefix + save_name + ".dat"):
		var file = FileAccess.open(prefix + save_name + ".dat", FileAccess.READ)
			
		loaded_player = build_player_data(file.get_var())
		loaded_story = build_story_data(file.get_var())
		loaded_world = build_world_data(file.get_var())
		
		return true
	else: 
		return false
		
func build_player_data(player_dict: Dictionary) -> PlayerData:
	var player_data = PlayerData.new()
	
	var player_script = player.get_script()
	
	#print(player_dict)
	
	#get all properties in the player script- in case i add more later :D 
	for property in player_script.get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			player_data.set(property.name, player_dict[property.name])
	
	player_data.inventory = build_inventory_data(player_dict["inventory"])
	return player_data
	
func build_inventory_data(inventory_dict: Dictionary) -> InventoryData:
	var inventory_data = InventoryData.new()
	for val in inventory_dict:
		var arr = inventory_dict[val]
		if arr.size() > 0:
			var slot = SlotData.new()
			var item_name = "res://Game Logic/item/items/" + arr[1] + ".tres"
			#TODO: determine if this needs to be threaded
			slot.item_data = ResourceLoader.load(item_name)
			slot.quantity = arr[0]
			inventory_data.slot_datas.append(slot)
		else:
			inventory_data.slot_datas.append(null)
		
	return inventory_data

func build_story_data(story_dict: Dictionary) -> StoryData:
	var story_data = StoryData.new()
	
	var story_script = story.get_script()
	
	#get all properties in the player script- in case i add more later :D 
	for property in story_script.get_script_property_list():
		if property.name.right(3) != ".gd":
			story_data.set(property.name, story_dict[property.name])
	
	return story_data
	
func build_world_data(world_dict: Dictionary) -> WorldData:
	var world_data = WorldData.new()
	
	world_data.world_seed = world_dict.world_seed
	world_data.world_size = world_dict.world_size
	world_data.chunk_size = world_dict.chunk_size
	
	var chunk_datas: Array[ChunkData] = []
	for chunk in world_dict.chunk_datas:
		chunk_datas.append(build_chunk_data(chunk))
		
	world_data.chunk_datas = chunk_datas
		
	return world_data
	
func build_chunk_data(chunk_dict: Dictionary) -> ChunkData:
	var chunk_data = ChunkData.new()
	
	chunk_data.chunk_size = chunk_dict.chunk_size
	chunk_data.chunk_position = chunk_dict.chunk_position
	chunk_data.biome = chunk_dict.biome
	
	if chunk_dict.has("entities"):
		chunk_data.entities = build_entities_data(chunk_data.entities)
		
	var square_datas: Array[SquareData] = []
	for square_dict in chunk_dict.square_datas:
		square_datas.append(build_square_data(square_dict))
	chunk_data.square_datas = square_datas
	
	return chunk_data
	
func build_square_data(square_dict: Dictionary) -> SquareData:
	var square_data = SquareData.new()
	
	for property in square_data.get_script().get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			square_data.set(property.name, square_dict[property.name])
			
	if square_dict.has("inventory"):
		square_data.inventory = build_inventory_data(square_dict.inventory)
	
	return square_data

#again, no clue if this works
#your problem now fuckhead! 
func build_entities_data(entity_dict: Dictionary) -> Array[EntityData]:
	var all_entities_arr : Array[EntityData] = []
	for id in entity_dict:
		var entity = entity_dict[id]
		#TODO:
		#I DONT exactly know how entities are going to work.
		
	
	return all_entities_arr
