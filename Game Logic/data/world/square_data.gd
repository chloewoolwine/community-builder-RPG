extends Resource
class_name SquareData

var chunk_location: Vector2

var elevation: int
var water_saturation: int 
var fertility: int 
enum SquareType{Dirt, Rock, Water, Sand}
var type: SquareType

enum SquareStatus {EMPTY, PASSABLE, IMPASSABLE}
var status: SquareStatus
var object_id : String #NULL if empty C:
var inventory : InventoryData #NULL if not chest
