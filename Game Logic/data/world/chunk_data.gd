extends Resource
class_name ChunkData

static var CHUNK_SIZE: Vector2

var chunk_position : Vector2
var tile_datas : Array[TileData]

enum Biome{Dead, Forest}
var biome : Biome

#entities that are in this chunk
var entities : Array[EntityData]
