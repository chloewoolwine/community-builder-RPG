extends Node2D
class_name WorldManager

#may need to do a list of chunk datas, in case multiple chunks chage at once?
signal square_changed(square_datas: Array[SquareData], chunk_data: ChunkData)
signal load_chunk(chunk_data: ChunkData)

signal entity_entered_chunk(new_chunk_data: ChunkData, \
							old_chunk_data: ChunkData, \
							entity_data: EntityData)

@export var world_data: WorldData
