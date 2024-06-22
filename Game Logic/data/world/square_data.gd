extends Resource
class_name SquareData

var mychunk: ChunkData

var elevation: int
var water_saturation: int 

enum SquareStatus {EMPTY, PASSABLE, IMPASSABLE}
var status: SquareStatus

var object_id : String #NULL if empty C:
var inventory : InventoryData #NULL if not chest
