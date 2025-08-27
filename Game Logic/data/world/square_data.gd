extends Resource
class_name SquareData

## Overall location in chunk- layer irrelevant
@export var location_in_chunk: Vector2i

@export var elevation: int
#0 - Dry 1 - Moist 2- Wet 3 - Very Wet 4- WATER TILE 5- DEEP WATER
@export var water_saturation: int 
@export var fertility: int 
@export var pollution: int 
enum SquareType{Dirt, Grass, Rock, Sand}
@export var type: SquareType
# instead- list of objects, 0 always being floor, 1 being main, 2 being roof, rest being decor
@export var object_data: Array[ObjectData]
