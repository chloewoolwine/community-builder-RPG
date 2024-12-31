extends StaticBody2D
class_name InteractionHitbox

signal player_interacted(hitbox:InteractionHitbox)

@export var is_chest : bool = false
@export var is_entity : bool = false
@export var needs_tool : bool = false
@export var tool_required : ItemDataTool.WeaponType 

var current_elevation: int
var accepting_interactions : bool = true

# the player checks if they have the tool, and if they are at the right elevation
func player_interact()-> void:
	player_interacted.emit(self)

func set_to_wall(val: bool) -> void: 
	self.set_collision_layer_value(current_elevation + 10, val)
