extends Resource
class_name ChunkData

## Size of chunk x * y
@export var chunk_size: Vector2i
## Position of chunk in terms of other chunks
## Position of chunk in worldspace = chunk_position * chunk_size
@export var chunk_position : Vector2i

## Biome of chunk- 
## Not entirely sure what this is going to do, yet, 
## I think it's just going to be for terrain generation? 
## then particle effects/entity spawns/music will be determined
## by the aggregate number of tile types. 
## like terraria!
enum Biome{Dead, Forest, Deepforest, Wasteland, Shrubland, Cityscape, Grassland, EvilWetland, Wetland}
@export var biome : Biome

## Entities that are in this chunk
# this isn't going to work as an array because of 
# https://github.com/godotengine/godot-docs/issues/8245 
# hhhhhhhhh
@export var entities : Array[EntityData]

## Granular info for tiles in the chunk
@export var square_datas : Dictionary
#
