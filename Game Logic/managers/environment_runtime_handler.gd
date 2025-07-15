extends Node2D
class_name EnvironmentRuntime

@onready var world_manager: WorldManager = $".."
@onready var trh: TerrainRulesHandler = $"../TerrainRulesHandler"

@export var time_between_calculations: int

func _ready() -> void:
	pass

func _on_tick(_day:int, _hour:int, _minute:int) -> void:
	_run_water_calc_loaded()

func _run_water_calc_loaded() -> void:
	# water rules! (for base biome)
	# - water nearby sources radiate out from tile
	# - closest - 3 
	# - 2-3 tiles ** - 2 
	
	# ** - this will reset as you go down hill. 
	# meaning, a pond on level 3 can potentially water 6 tiles in every direction going downhill
	
	# we start with 1
	# a player can only water to 2. 
	# 3 NEEDS a water source 
	# plants will not complain if they have more moisture than needed
	# crops - need 2 
	# wild plants - most need 1, rarer plants will need more 
	
	#certain structures will Suck Moisture, but we can get to that later
	var all_chunks := world_manager._world_data.chunk_datas
	var chunks := trh.loaded_chunks
	if chunks.is_empty():
		return
	
	#do not change values from unloaded chunks... unloaded chunks (and weather effects)
	#will be handled elsewhere 
	pass
