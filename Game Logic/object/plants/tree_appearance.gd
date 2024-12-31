extends PlantAppearance
class_name TreeAppearance

@export var leaf_growth_textures: Array[Texture2D]
@export var leaf_growth_texture_offset: Array[int]
@export var stump_texture: Texture2D

@onready var sprite_2d_2: Sprite2D = $Sprite2D2

func _ready() -> void:
	fix_sprites()

func change_growth_stage(stage: int) -> void:
	if stage < growth_stage_textures.size():
		current_texture = stage
	else:
		current_texture = growth_stage_textures.size()-1
	fix_sprites()

# just here to make things look prettier
func fix_sprites() -> void: 
	if current_texture == -1:
		sprite_2d.texture = stump_texture
		sprite_2d.offset.y = leaf_growth_texture_offset[leaf_growth_texture_offset.size()-1]
		sprite_2d_2.texture = null
		return
	sprite_2d.texture = growth_stage_textures[current_texture]
	sprite_2d.offset.y = growth_stage_texture_offset[current_texture]
	if current_texture > 0: 
		sprite_2d_2.texture = leaf_growth_textures[current_texture - 1] # baby sapling is 1 sprite
		sprite_2d_2.offset.y = leaf_growth_texture_offset[current_texture - 1]
