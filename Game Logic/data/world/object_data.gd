extends Resource
class_name ObjectData

#enum OBJECT_TYPE{FLOOR, BASE, ROOF, DECOR}

#WARNING!
#objects are not tested enough in saver loader
@export var object_id : String # the path to which the corresponding scene exists- when this is a pointer, this is Constants.POINTER
@export var chunk: Vector2i
@export var position: Vector2i # - elevation nonwithstanding
#@export var originator: Location = null #POINTERS ONLY ! 

@export var inventory : InventoryData #NULL if not chest
@export var object_tags : Dictionary #things like customized colors, growth stages, etc all saved here
# Acceptable tags: 
# age : int
@export var size: Vector2i #how chunky this object is
# 1x1 = self explanatory
# 1x2/1x3/.. = position is leftmost topmost square
# 2x2 = top left
# 3x3 = middle
@export var additive: bool # meaning it can be appended onto the array. 
#@export var slot: OBJECT_TYPE # where it goes in the enum list
# floors - will be applied like "till", can go under all objects, only one
# base - immovable. walls, furniture, tree trunk, crop- the "Centerpiece"
# roof - above slot. can go above all objects, only one, usually other requirements exist
# decor - TODO: this will be objects that can be put on walls, rugs, other cutsie stuff
@export var last_loaded_minute: int 
