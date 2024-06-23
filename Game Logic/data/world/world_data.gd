extends Resource
class_name WorldData

#WARNING! WARNING! CHLOE LOOK ME IN THE EYES RIGHT NOW
#if you edit *any* of these values you are going to also have to update
#     ~~~ saveloader.gd ~~~
#saverloader does NOT automatically detect changes in worlds/chunks/squares 
#(except for entities)

@export var world_seed: int
@export var world_size: Vector2
@export var chunk_size: Vector2

@export var chunk_datas: Array[ChunkData]
#to load chunks:
#i will STORE the current chunk that the player is standing in
#when the player moves in a cardinal direction, i should be able 
#to calculate the proper chunk to load
