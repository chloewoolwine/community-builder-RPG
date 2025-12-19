extends Node
class_name AgeingComponent

signal update_age_in_data(new_age:int)
signal max_age_reached(max_age: int)

var current_age:int

@export var age_multiplier:float = 1.0 #at what ratio should this object rage? higher = faster
@export var max_age_minutes: int = 60

func minute_pass(day:int, hour:int, minute:int) -> void:
	var current_minute := EnvironmentLogic.get_minutes(day, hour, minute)
	if current_age < current_minute - 1:
		#print("last loaded minute: ", last_loaded_age, " curr:", current_minute)
		#this may make it so objects age unpredictably if unloaded for a long period of time (depending on mutliplier at the time of load)
		#i can handle this when i do the non-loaded chunk update logic 
		var age_increase := age_multiplier * (current_minute - current_age)
		update_age_in_data.emit(current_age + int(age_increase))
		current_age += int(age_increase)
		if current_age >= max_age_minutes:
			max_age_reached.emit(max_age_minutes)
