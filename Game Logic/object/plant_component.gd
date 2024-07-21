extends Node2D
class_name PlantComponent

signal change_stage(new_stage: int)

@export var growth_stage_minutes: Array[int] #how many growth stages + minutes
@export var current_growth_stage: int
@export var loot_table: LootTable
@export var destroy_on_harvest: bool

var mature : bool
var age : int: #counted in whole minutes
	set(value):
		age = value
		if !mature:
			if age >= growth_stage_minutes[current_growth_stage + 1]:
				current_growth_stage += 1
				change_stage.emit()
