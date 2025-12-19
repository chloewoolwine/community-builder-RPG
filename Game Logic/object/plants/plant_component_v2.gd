extends Node
class_name PlantComponentV2

signal change_age_rate(new_rate: float)
signal propogate_me(my_baby: ObjectData, with_tags: Dictionary)
@export var plant_gen_data: PlantGenData
@export var propogation_baby_name: String # really only need objectId + tags

func tile_changed(_new_square_data: SquareData) -> void:
	# Placeholder for future logic when tile changes
	if false:
		change_age_rate.emit(1.0)

func try_propogate() -> void:
	var prop_chance: float = float(Constants.DAYS_TO_MINUTES * plant_gen_data.prop_days) # magic number- minutes per day
	if prop_chance > 0 && randf() < 1.0 / prop_chance:
		#print("plant at ", location, " propagating")
		propogate_me.emit(propogation_baby_name)
		#TODO: something with object tags with propogation, probably 
		#will have to write specific functions for each and select them with string name (from a settings class maybe?)