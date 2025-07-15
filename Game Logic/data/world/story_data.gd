extends Resource
class_name StoryData

@export var game_minute: int
enum Weather{SUNNY, RAINING}
@export var current_weather : Weather
@export var wind_direction : int

#story flags
@export var tutorial_completed : bool
