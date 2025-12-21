extends Node
class_name AgeingComponent

signal update_age_in_data(new_age: float)
signal max_age_reached(max_age: int)

var current_age:float
var prev_minute:int

@export var age_multiplier:float = 1.0 #at what ratio should this object rage? higher = faster
@export var max_age_minutes: int = -1

var owner_ready:bool = false

func minute_pass(day:int, hour:int, minute:int) -> void:
	var current_minute := EnvironmentLogic.get_minutes(day, hour, minute)
	if current_age == 0: #just spawned in!
		prev_minute = current_minute - 1
	if max_age_minutes == 60:
		#print("AAA")
		pass
	if max_age_minutes == 6000:
		#print("agh")
		pass
	if prev_minute <= current_minute - 1:
		#print("last loaded minute: ", last_loaded_age, " curr:", current_minute)
		#this may make it so objects age unpredictably if unloaded for a long period of time (depending on mutliplier at the time of load)
		#i can handle this when i do the non-loaded chunk update logic 
		var age_increase := age_multiplier * (current_minute - prev_minute)
		update_age_in_data.emit(current_age + age_increase)
		current_age += age_increase
		if current_age >= max_age_minutes && max_age_minutes != -1:
			#print("max age reached !! by ", owner.object_id)
			max_age_reached.emit(max_age_minutes)
	prev_minute = current_minute
