extends Resource
class_name ObjectData

#WARNING!
#objects are not set up to be saved in SaverLoader
#TODO: That

var object_id : String
var chunk : Vector2
var location : Vector2

var inventory : InventoryData #NULL if not chest
var object_tags : Dictionary #things like customized colors, growth stages, etc all saved here
