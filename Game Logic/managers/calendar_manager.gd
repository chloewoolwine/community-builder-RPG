extends CanvasModulate
class_name CalendarManager

signal time_tick(day:int, hour:int, minute:int)

@export var proccessTime : bool = false
@export var ingame_speed : float = 1.0 #ratio of ingame 1 minute to 1 rl second
@export var initial_hour: int = 12 
@export var light_gradient: GradientTexture1D

#the value "minute" was in story data when we loaded up the game 
var last_loaded_minute: int

var minutes_per_day : int = 1440
var minutes_per_hour : int  = 60
var gametime_to_minute : float = (2 * PI) / minutes_per_day
var previous_minute: int = -1
var time: float = 0

var curr_year : int
var curr_date : int #these are meant to keep track of Total days from a savegame state
var curr_hour: int
var curr_minute: int

func _ready() -> void:
	self.visible = true
	previous_minute = get_parent().story_data.game_minute
	change_time_of_day(previous_minute)
	# TODO: year and date calculations from last_loaded_minutes

func _process(delta: float) -> void:
	if proccessTime:
		time += delta * ingame_speed * gametime_to_minute
		update_lighting()
		calculate_gametime()
	
func calculate_gametime() -> void: 
	var total_minutes := int(time/gametime_to_minute)
	
	@warning_ignore("integer_division")
	var day := int(total_minutes/minutes_per_day)
	var minutes_of_today := total_minutes % minutes_per_day
	@warning_ignore("integer_division")
	var hour := int(minutes_of_today/minutes_per_hour)
	var minute := int(minutes_of_today % minutes_per_hour)
	
	if previous_minute != minute: 
		previous_minute = minute
		time_tick.emit(day, hour, minute)
		curr_date = day
		curr_hour = hour
		curr_minute = minute
		print(str("day: ", day, " time: ", hour, ":", minute))

func change_time_of_day(target: int) -> void:
	time = target * gametime_to_minute
	print(time)
	update_lighting()
	calculate_gametime()
	print(str("time of day changed to: ", target))

func update_lighting() -> void:
	self.color = light_gradient.gradient.sample(
		(sin(time - PI / 2) + 1.0) / 2.0)

func formatted_datetime() -> String:
	return str(curr_year, "  ", curr_date, ":", curr_hour, ":", curr_minute)
