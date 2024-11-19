extends Resource
class_name ObjectData

#WARNING!
#objects are not set up to be saved in SaverLoader
#TODO: That
var object_id : String

var inventory : InventoryData #NULL if not chest
var object_tags : Dictionary #things like customized colors, growth stages, etc all saved here

## Default object is a fully mature poplar tree
func _init(objectid : String= "poplar_tree", inventor:InventoryData = null, objecttags:Dictionary= {"growth_state":"mature"}) -> void:
	self.object_id = objectid
	self.inventory = inventor
	self.object_tags = objecttags
