extends Node2D
class_name PlantComponent

# Handles growth and self propagation activity 

signal change_stage(new_stage: int, collision: bool)
signal propagate_plant(location: Vector2i, object_id: String)

@onready var generic_plant: GenericPlant = $".."

@export var growth_stage_minutes: Array[int] #how many growth stages + minutes
@export var collision: Array[bool] ## if the growth stage makes the tileimmovable
@export var destroy_on_harvest: bool
@export var prop_days: float = 0 ## how many days in between propagation attempts
@export_enum("close", "medium", "far", "custom") var propagation_type : String
@export_range(1, 5) var target_moisture: int

var mature : bool
var age : int #counted in whole minutes, -1 is dead
var current_growth_stage: int

func minute_pass(_day:int, _hour:int, _minute:int) -> void:
	var moisture := generic_plant.square_data.water_saturation
	if age != -1:  #-1 is dead 
		# if the moisture is wrong, will literally grow slower 
		# but, not trees
		if moisture != target_moisture and !generic_plant.is_tree:
			if _day % 2 == 0:
				set_age(age+1)
		else:
			set_age(age+1)
			
	if mature and prop_days > 0:
		var prop_chance: float = 1.0 / float(1440*prop_days)
		if randf() < prop_chance:
			print("tree at ", generic_plant.object_data.position, " propagating")
			var my_loc := Location.new(generic_plant.object_data.position, generic_plant.object_data.chunk)
			var new_loc : Location
			if propagation_type == "close":
				new_loc = my_loc.get_location(Vector2i(randi_range(-2, 2), randi_range(-2, 2)))
			elif propagation_type == "medium": 
				new_loc = my_loc.get_location(Vector2i(randi_range(-10, 10), randi_range(-10, 10)))
			elif propagation_type == "far":
				new_loc = my_loc.get_location(Vector2i(randi_range(-20, 20), randi_range(-20, 20)))
			else:
				#custom is not implemented yet!
				new_loc = my_loc.get_location(Vector2i(-1, 1))
			propagate_plant.emit(new_loc, generic_plant.object_id)

func set_age(value: int) -> void:
	#print("new age: ", value)
	age = value
	if generic_plant.object_data:
		generic_plant.object_data.object_tags["age"] = age
	# if we are dead, give up 
	if age == -1:
		current_growth_stage = age
		change_stage.emit(current_growth_stage, true)
		return
	elif !mature:
		if age >= growth_stage_minutes[current_growth_stage + 1]:
			current_growth_stage = current_growth_stage + 1 
			while current_growth_stage + 1 < growth_stage_minutes.size()-1 and age >= growth_stage_minutes[current_growth_stage + 1]:
				current_growth_stage = current_growth_stage + 1 
			change_stage.emit(current_growth_stage, collision[current_growth_stage])
		if current_growth_stage == growth_stage_minutes.size()-1:
			mature = true
