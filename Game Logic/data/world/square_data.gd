extends Resource
class_name SquareData

## Overall location in chunk- layer irrelevant
@export var location_in_chunk: Vector2i

@export var elevation: int
@export var water_saturation: int 
@export var fertility: int 
enum SquareType{Dirt, Grass, Rock, Water, DeepWater, Sand}
@export var type: SquareType
@export var object_data: ObjectData
