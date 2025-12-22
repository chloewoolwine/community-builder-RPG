extends Node
class_name PlantComponentV2

signal change_age_rate(new_rate: float)
signal propogate_me(relative_loc: Location, my_baby: ObjectData, with_tags: Dictionary)
signal request_square_at(relative_loc: Location)
@export var plant_gen_data: PlantGenData
@export var current_stage_num: int
@export var next_stage_name: String
@export var propogation_baby_name: String # really only need objectId + tags
@export var death_stage_name: String

func tile_changed(square: SquareData) -> float:
	# Placeholder for future logic when tile changes
	print("Square modified. doing something.")
	var rate := 1.0
	if square.type not in plant_gen_data.target_tiles: #how did this even happen?
		rate -= 1
	if square.pollution > plant_gen_data.pollution_tolerance:
		rate -= 1
	if square.water_saturation > plant_gen_data.target_moisture:
		rate -= .2
	if square.water_saturation < plant_gen_data.target_moisture:
		rate -= .9
	if square.fertility < plant_gen_data.target_nutrition:
		rate -= .4
	if square.fertility > plant_gen_data.target_nutrition:
		rate += .2
	if rate < 0:
		rate = 0
	change_age_rate.emit(rate)
	return rate

func try_propogate() -> void:
	if propogation_baby_name.is_empty():
		return
	var prop_chance: float = float(Constants.DAYS_TO_MINUTES * plant_gen_data.spread_chance)
	if prop_chance > 0 && randf() < 1.0 / prop_chance:
		#print("plant at ", location, " propagating")
		var zero_loc := Location.new(Vector2i.ZERO, Vector2i.ZERO)
		var new_loc := zero_loc.get_location(Vector2i(randi_range(-plant_gen_data.spread_distance, plant_gen_data.spread_distance), randi_range(-plant_gen_data.spread_distance, plant_gen_data.spread_distance)))
		request_square_at.emit(new_loc)
		#TODO: something with object tags with propogation, probably 
		#will have to write specific functions for each and select them with string name (from a settings class maybe?)

func request_square_callback(square: SquareData = null, relative_loc: Location = null) -> void: 
	if relative_loc == null || square == null:
		return
	var success: bool = true
	##TODO: i need to specifically verify how moisture, elevation, nutrition is going to work. 
	##for now, only Pollution will be HARD, moisture will be Soft
	if square.water_saturation < plant_gen_data.target_moisture:
		success = false
	if square.type not in plant_gen_data.target_tiles:
		success = false
	if square.pollution > plant_gen_data.pollution_tolerance:
		success = false
	#if square.fertility < plant_gen_data.target_nutrition:
		#success = false
	if success:
		#print("propogate success for: ", propogation_baby_name)
		propogate_me.emit(relative_loc, propogation_baby_name, {})
