extends Node2D
class_name PlantComponent

signal change_stage(new_stage: int)

@export var growth_stage_minutes: Array[int] #how many growth stages + minutes
@export var current_growth_stage: int
@export var loot_table: LootTable
@export var destroy_on_harvest: bool

var mature : bool
var age : int #counted in whole minutes

func minute_pass(_day:int, _hour:int, _minute:int) -> void:
	set_age(age+1)

func set_age(value: int) -> void:
	age = value
	if !mature:
		if age >= growth_stage_minutes[current_growth_stage + 1]:
			current_growth_stage += 1
			change_stage.emit(current_growth_stage)
		if current_growth_stage == growth_stage_minutes.size()-1:
			mature = true
