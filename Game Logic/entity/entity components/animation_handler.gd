extends Node
class_name AnimationHandler

signal jump_finished()
@export var sprites : Array[AnimatedSprite2D]
@export var animation_player : AnimationPlayer

func _ready() -> void:
	for anim_name in animation_player.get_animation_list():
		var anim: Animation = animation_player.get_animation(anim_name)
		#TODO: in the future im probably going to have the launch and hit ground animations be seperate, and those are the only ones
		# that shouldnt loop
		anim.loop_mode = Animation.LOOP_NONE if "Idle" not in anim_name && "Walk" not in anim_name else Animation.LOOP_LINEAR

func flip_all_sprites(left: bool) -> void:
	for sprite in sprites:
		sprite.set_flip_h(left)

var prev_append:String = "Down"
var prev_aname:String = "Idle"
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
	#print(aname, append)
	if prev_aname == aname && prev_append == append:
		animation_player.play(StringName(aname + append))
		return
	if aname == prev_aname:
		# If the animation name is the same as the previous one, we can blend the animations
		var position: float = animation_player.current_animation_position
		animation_player.play(StringName(aname + append))
		animation_player.seek(position, true)
	else:
		animation_player.play(StringName(aname + append))
	prev_aname = aname
	prev_append = append

func on_jump_finished() -> void:
	print("jump finished")
	jump_finished.emit()
