extends Node
class_name PlantComponentV2

#TODO:
	#Tile logic
	#Propogation tags

signal change_age_rate(new_rate: float)
signal propogate_me(location: Location, my_baby: ObjectData, with_tags: Dictionary)
@export var plant_gen_data: PlantGenData
@export var current_stage_num: int
@export var next_stage_name: String
@export var propogation_baby_name: String # really only need objectId + tags
@export var death_stage_name: String

func tile_changed(_new_square_data: SquareData) -> void:
	# Placeholder for future logic when tile changes
	if false:
		change_age_rate.emit(1.0)

func try_propogate() -> void:
	if propogation_baby_name.is_empty():
		return
	var prop_chance: float = float(Constants.DAYS_TO_MINUTES * plant_gen_data.spread_chance)
	if prop_chance > 0 && randf() < 1.0 / prop_chance:
		#print("plant at ", location, " propagating")
		var zero_loc := Location.new(Vector2i.ZERO, Vector2i.ZERO)
		var new_loc := zero_loc.get_location(Vector2i(randi_range(-plant_gen_data.spread_distance, plant_gen_data.spread_distance), randi_range(-plant_gen_data.spread_distance, plant_gen_data.spread_distance)))
		propogate_me.emit(new_loc, propogation_baby_name, {})
		#TODO: something with object tags with propogation, probably 
		#will have to write specific functions for each and select them with string name (from a settings class maybe?)
		
