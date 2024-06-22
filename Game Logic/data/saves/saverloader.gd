extends Node
class_name SaverLoader

var prefix = "user://"
var save_name: String

#*ALL* this node worries about is getting whatever is in these three datas into a file
#and then getting them out of a file
@export var player : PlayerData
@export var story_data : StoryData #contains story flags, time of day, weather, environment status, etc..
@export var world : WorldData #data about maps, contains chunk data, which contain entities


func save() -> bool:
	if !check_for_vars():
		return false
		
	if !save_name || save_name.length() == 0:
		save_name = player.name + Time.get_date_string_from_system() + ".dat"
	
	var old_player_dict 
	var old_story_dict 
	#var old_world_dict 
	#if FileAccess.file_exists(prefix + save_name):
		#print("SAVE FILE EXISTS !")
	
	
	var player_dict = create_player_dict()
	var story_dict = create_story_dict()
	#var world_dict = create_world_dict()
	
	print(player_dict)
	print(story_dict)
	
	
	var file = FileAccess.open(prefix + save_name, FileAccess.WRITE)
	
	file.store_var(player_dict)
	file.store_var(story_dict)
	file.close()
		
	return true
	
func create_player_dict() -> Dictionary:
	var player_dict = {}
	
	var player_script = player.get_script()
	
	for property in player_script.get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			player_dict[property.name] = player.get(property.name)
	
	player_dict["inventory"] = create_inventory_dict(player.inventory)
	return player_dict
	
func create_story_dict() -> Dictionary:
	var story_dict = {}
	
	var story_script = story_data.get_script()
	
	for property in story_script.get_script_property_list():
		if property.name.right(3) != ".gd" && property.name != "inventory":
			story_dict[property.name] = story_data.get(property.name)

	return story_dict
	
func create_world_dict() -> Dictionary:
	var world_dict = {}
	return world_dict
	
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
	if !story_data:
		push_error("attempted to save without valid story data")
		return false
	return true

func load(save_name) -> bool:
	if FileAccess.file_exists(prefix + save_name + ".dat"):
		var file = FileAccess.open(prefix + save_name + ".dat", FileAccess.READ)
			
		var player_dict = file.get_var()
		var story_dict = file.get_var()
		
		print(player_dict)
		print(story_dict)
		return true
	else: 
		return false
