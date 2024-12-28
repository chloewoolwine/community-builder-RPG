extends PlantAppearance
class_name TreeAppearance

@export var leaf_growth_textures: Array[Texture2D]
@export var leaf_growth_texture_offset: Array[int]

@onready var sprite_2d_2: Sprite2D = $Sprite2D2

var stump_texture: Texture2D

func _ready() -> void:
	sprite_2d.texture = growth_stage_textures[current_texture]
	if current_texture > 0: 
		sprite_2d_2.texture = leaf_growth_textures[current_texture - 1] # baby sapling is 1 sprite
		sprite_2d_2.offset.y = leaf_growth_texture_offset[current_texture - 1]

func change_growth_stage(stage: int) -> void:
	if stage < growth_stage_textures.size():
		current_texture = stage
		sprite_2d.texture = growth_stage_textures[stage]
		sprite_2d.offset.y = growth_stage_texture_offset[stage]
	else:
		current_texture = growth_stage_textures.size()-1
		sprite_2d.texture = growth_stage_textures[growth_stage_textures.size()-1]
		sprite_2d.offset.y = growth_stage_texture_offset[growth_stage_textures.size()-1]
	if current_texture > 0: 
		sprite_2d_2.texture = leaf_growth_textures[current_texture - 1] # baby sapling is 1 sprite
		sprite_2d_2.offset.y = leaf_growth_texture_offset[current_texture - 1]
