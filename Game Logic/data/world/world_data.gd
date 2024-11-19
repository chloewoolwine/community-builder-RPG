extends Resource
class_name WorldData

#WARNING! WARNING! CHLOE LOOK ME IN THE EYES RIGHT NOW
#if you edit *any* of these values you are going to also have to update
#     ~~~ saveloader.gd ~~~
#saverloader does NOT automatically detect changes in worlds/chunks/squares 
#(except for entities)

@export var world_seed: int
@export var world_size: Vector2i
@export var chunk_size: Vector2i

# GOTTA CAHNGE THIS IN SAVER LOADER YOU HAVENT DONE THAT YET!
# Key- Vector2i, place of chunk, value- chunk data
@export var chunk_datas: Dictionary
#to load chunks:
#i will STORE the current chunk that the player is standing in
#when the player moves in a cardinal direction, i should be able 
#to calculate the proper chunk to load
