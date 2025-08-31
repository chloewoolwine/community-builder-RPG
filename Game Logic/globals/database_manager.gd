extends Node
class_name DatabaseManager

static var WORLD_DATABASE:Database = preload("res://Game Logic/data/WorldDatabase.gddb")

static func fetch_plant_gen(name:StringName) -> PlantGenData:
	return WORLD_DATABASE.fetch_data(&"GenerationData", name)
