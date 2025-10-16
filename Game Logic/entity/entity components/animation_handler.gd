extends Node
class_name AnimationHandler

@export var sprites : Array[AnimatedSprite2D]

@export var animation_player : AnimationPlayer
@export var animation_tree : AnimationTree

func flip_all_sprites(left: bool) -> void:
	for sprite in sprites:
		sprite.set_flip_h(left)

func set_blend_position(aname: String, pos: Vector2) -> void:
	animation_tree.set(str("parameters/", aname, "/BlendSpace2D/blend_position"), pos)
	
func travel_to_anim(aname: String) -> void:
	animation_tree.get("parameters/playback").travel(aname)
	
func travel_to_and_blend(aname: String, pos: Vector2) -> void:
	travel_to_anim(aname)
	set_blend_position(aname, pos)
