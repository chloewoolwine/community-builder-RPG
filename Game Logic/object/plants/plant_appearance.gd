extends Node2D
class_name PlantAppearance

@export var growth_stage_textures: Array[Texture2D]
@export var growth_stage_texture_offset: Array[int]
#TODO: animations, done by a shader, whenever player walks though
#going to need normal maps for that prolly

var current_texture: int = 0

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite_2d.texture = growth_stage_textures[current_texture]
	sprite_2d.offset.y = growth_stage_texture_offset[current_texture]

func change_growth_stage(stage: int) -> void:
	if stage < growth_stage_textures.size():
		current_texture = stage
		sprite_2d.texture = growth_stage_textures[stage]
		sprite_2d.offset.y = growth_stage_texture_offset[stage]
	else:
		current_texture = growth_stage_textures.size()-1
		sprite_2d.texture = growth_stage_textures[growth_stage_textures.size()-1]
		sprite_2d.offset.y = growth_stage_texture_offset[growth_stage_textures.size()-1]

func playharvestanim() -> void:
	#TODO: animation, cute particle effect
	pass
