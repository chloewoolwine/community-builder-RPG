extends Node
class_name DatabaseManager

static var WORLD_DATABASE:Database = preload("res://Game Logic/data/WorldDatabase.gddb")

#TODO: i should really make tests for this shit lol

static func fetch_plant_gen_all(mname:StringName) -> PlantGenData:
	return WORLD_DATABASE.fetch_data(&"GenerationData", mname)

static func fetch_plant_category(mname:StringName) -> Dictionary:
	return WORLD_DATABASE.fetch_category_data(&"GenerationData", mname)

static func fetch_object_data(mname:StringName) -> ObjectData:
	return WORLD_DATABASE.fetch_data(&"ObjectDatas", mname)
