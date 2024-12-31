extends Node2D
class_name PlantComponent

# Handles growth and self propagation activity 

signal change_stage(new_stage: int, collision: bool)

@export var growth_stage_minutes: Array[int] #how many growth stages + minutes
@export var collision: Array[bool] ## if the growth stage makes the tileimmovable
@export var current_growth_stage: int
@export var destroy_on_harvest: bool

var mature : bool
var age : int #counted in whole minutes, -1 is dead

func minute_pass(_day:int, _hour:int, _minute:int) -> void:
	if age != -1:  #-1 is dead 
		set_age(age+1)

func set_age(value: int) -> void:
	#print("new age: ", value)
	age = value
	get_parent().object_data.object_tags["age"] = age
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
