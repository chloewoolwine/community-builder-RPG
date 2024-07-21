extends Node2D
class_name PlantApperance

@export var growth_stage_textures: Array[Texture2D]
#TODO: animations, done by a shader, whenever player walks though
#going to need normal maps for that prolly

var current_texture: int = 0

@onready var sprite_2d := $Sprite2D

func _ready() -> void:
	sprite_2d.texture = growth_stage_textures[current_texture]

func change_growth_stage(stage: int) -> void:
	if stage < growth_stage_textures.size():
		sprite_2d.texture = growth_stage_textures[stage]
	else:
		sprite_2d.textre = growth_stage_textures[growth_stage_textures.size()-1]

func playharvestanim() -> void:
	#TODO: animation, cute particle effect
	pass
