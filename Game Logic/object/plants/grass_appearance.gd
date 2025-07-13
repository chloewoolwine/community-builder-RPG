extends PlantAppearance
class_name GrassAppearance

@onready var sprite_2d_1: Sprite2D = $Sprite2D2
@onready var sprite_2d_2: Sprite2D = $Sprite2D3
@onready var sprite_2d_3: Sprite2D = $Sprite2D4

@export var growth_stage_textures_1: Array[Texture2D]
@export var growth_stage_textures_2: Array[Texture2D]
@export var growth_stage_textures_3: Array[Texture2D]

func _ready() -> void:
	change_sprite_offset(sprite_2d, growth_stage_textures, current_texture)
	if current_texture > 0: 
		change_sprite_offset(sprite_2d, growth_stage_textures_1, current_texture-1)
		change_sprite_offset(sprite_2d, growth_stage_textures_2, current_texture-1)
		change_sprite_offset(sprite_2d, growth_stage_textures_3, current_texture-1)

func change_growth_stage(stage: int) -> void:
	if stage < growth_stage_textures.size():
		current_texture = stage
		change_sprite_offset(sprite_2d, growth_stage_textures, stage)
	else:
		current_texture = growth_stage_textures.size()-1
		change_sprite_offset(sprite_2d, growth_stage_textures, current_texture)
	if current_texture > 0: 
		print("changing other sprites")
		change_sprite_offset(sprite_2d_1, growth_stage_textures_1, current_texture-1)
		change_sprite_offset(sprite_2d_2, growth_stage_textures_2, current_texture-1)
		change_sprite_offset(sprite_2d_3, growth_stage_textures_3,current_texture-1)

func change_sprite_offset(sprite: Sprite2D, arr: Array[Texture2D], num: int) -> void:
	sprite.texture = arr[num]
