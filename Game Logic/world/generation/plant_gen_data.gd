extends Resource
class_name PlantGenData

enum PLANT_TYPE{
	Grass,
	Treee,
	Flower,
	Fungus,
	Crop
}
@export var object_id: String
@export var type: PLANT_TYPE

@export_category("Growth stage info")
@export var stage_num: int
@export var stage_mature: int

@export_category("Target Conditions")
@export_range(0,5) var target_moisture: int
@export var target_tile: SquareData.SquareType
#not implemented
@export var target_elevation: int
@export var target_nutrition: int 
@export var pollution_tolerance: int #(?)

@export_category("Propogation Parameters")
@export var spread_distance: int
@export_range(0,8) var density: int #how many plants am i OK being next too? 
@export var rarity: int
