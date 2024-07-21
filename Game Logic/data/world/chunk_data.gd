extends Resource
class_name ChunkData

var chunk_size: Vector2

var chunk_position : Vector2

enum Biome{Dead, Forest}
var biome : Biome

#entities that are in this chunk
var entities : Array[EntityData]
var square_datas : Array[SquareData]
var object_data : Array[ObjectData]
