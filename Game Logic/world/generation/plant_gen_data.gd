extends Resource
class_name PlantGenData

enum PLANT_TYPE{
	Grass,
	Treee,
	Flower,
	Fungus,
	Crop,
	Bush
}
@export var object_id: String
@export var type: PLANT_TYPE
@export var size: Vector2i = Vector2i.ONE

@export_category("Target Conditions")
@export_range(0,5) var target_moisture: int
@export var target_tiles: Array[SquareData.SquareType]
#not implemented
@export var target_elevation: int
@export var target_nutrition: int 
@export var pollution_tolerance: int #(?)
@export var shallow_water: bool
@export var deep_water: bool

@export_category("Propogation Parameters")
@export var spread_distance: int
@export var spread_chance: float
@export var density: int #how many plants am i OK being next too? 
@export var rarity: int
