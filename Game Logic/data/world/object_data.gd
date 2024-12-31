extends Resource
class_name ObjectData

#WARNING!
#objects are not set up to be saved in SaverLoader
#TODO: That
@export var object_id : String # the path to which the corresponding scene exists
@export var chunk: Vector2i
@export var position: Vector2i # - elevation nonwithstanding

@export var inventory : InventoryData #NULL if not chest
@export var object_tags : Dictionary #things like customized colors, growth stages, etc all saved here
# Acceptable tags: 
# growth_state : int
