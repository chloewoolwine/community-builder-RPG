extends StaticBody2D
class_name InteractionHitbox

enum TYPE{HAND, CHEST, TOOL, ENTITY}

signal player_interacted()

var type:TYPE
var tool_required : ItemDataTool.WeaponType 
@export var neighbor_searcher: Area2D ## Finds neighbors for things like walls (that should probably replaced with a tileset lol)
 
var current_elevation: int:
	set(value):
		if(elevation_handler != null):
			elevation_handler.current_elevation = value
			current_elevation = value
var accepting_interactions : bool = true

var elevation_handler: ObjElevationHandler

func _ready() -> void:
	for child in get_parent().get_children():
		if child is ObjElevationHandler:
			elevation_handler = child

# the player checks if they have the tool, and if they are at the right elevation
func player_interact()-> void:
	if accepting_interactions:
		player_interacted.emit()

#DEPRECIATED- going to use something else probably
func set_to_wall(val: bool, search_neighbors: bool = true) -> void: 
	#if get_parent() is GenericWall:
		#print('setting to a wall value, elevation = ', current_elevation)
	self.set_collision_layer_value(current_elevation + 10, val)
	if neighbor_searcher:
		#print("will search for neighbors now")
		neighbor_searcher.set_collision_mask_value(current_elevation + 10, search_neighbors)
