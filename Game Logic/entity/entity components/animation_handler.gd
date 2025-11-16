extends Node
class_name AnimationHandler

@export var sprites : Array[AnimatedSprite2D]

@export var animation_player : AnimationPlayer
@onready var new_body: AnimatedSprite2D = $"../PlayerOutfitHandler/NewBody"

var blend_pos: Vector2

func flip_all_sprites(left: bool) -> void:
	for sprite in sprites:
		sprite.set_flip_h(left)

var prev_append:String = "Down"
func travel_to_and_blend(aname: String, pos: Vector2) -> void:
	var append:String = prev_append
	flip_all_sprites(false)
	match pos.y:
		-1.0:
			append = "Up"
		1.0:
			append = "Down"
		0.0:
			if(pos.x != 0.0):
				append = "Right"
				if pos.x < 0:
					flip_all_sprites(true)
			else:
				append = prev_append
	#print(append)
	animation_player.play(StringName(aname + append))		
