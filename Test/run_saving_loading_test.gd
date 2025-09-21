@warning_ignore("empty_file")
#extends Node
#
#@onready var saver_loader:SaverLoader = $SaverLoader
#
## This saves the Data scenes into a NON SCENE FILE!
#
#func _ready() -> void:
	#saver_loader.world = make_random_world(20, 20)
	#var save:bool = saver_loader.save()
	#var load:bool = saver_loader.load_file("Boy2024-06-22")
	#
	##if compare_entities(saver_loader.player, saver_loader.loaded_player):
		##print("player good!")
	##else: 
		##print("player bad :c ")
		##print("------------save---------------")
		##print(saver_loader.player )
		##print("------------load---------------")
		##print(saver_loader.loaded_player)
		#
	##if compare_stories(saver_loader.story, saver_loader.loaded_story):
		##print("story good!")
	##else: 
		##print("story bad :c ")
		##print("------------save---------------")
		##print(saver_loader.story )
		##print("------------load---------------")
		##print(saver_loader.loaded_story)
		#
	#if compare_worlds(saver_loader.world, saver_loader.loaded_world):
		#print("world good!")
	#else: 
		#print("world bad :c ")
		#print("------------save---------------")
		#print(saver_loader.world )
		#print("------------load---------------")
		#print(saver_loader.loaded_world)
		#
#func compare_worlds(w1 : WorldData, w2 : WorldData) -> bool:
	#if w1 == null:
		#print("w1 is null")
		#return false
	#if w2 == null:
		#print("w2 is null")
		#return false
	#
	#if w1.world_seed != w2.world_seed:
		#print("world seed mismatch")
		#return false
	#if w1.world_size != w2.world_size:
		#print("world_size mismatch")
		#return false
	#if w1.chunk_size != w2.chunk_size:
		#print("chunk_size mismatch")
		#return false
	#
	#if w1.chunk_datas.size() != w2.chunk_datas.size():
		#print("chunk_datas.size() mismatch")
		#return false
		#
	#for x in range(0, w1.chunk_datas.size()):
		#if !compare_chunks(w1.chunk_datas[x], w2.chunk_datas[x]):
			#return false
	#return true
	#
#func compare_chunks(c1 : ChunkData, c2 : ChunkData) -> bool:
	#if c1 == null:
		#return false
	#if c2 == null:
		#return false
		#
	#if c1.chunk_size != c2.chunk_size:
		#print("chunk size mismatch")
		#return false
	#
	#if c1.chunk_position != c2.chunk_position:
		#print("chunk position mismatch")
		#return false
		#
	#if c1.biome != c2.biome:
		#print("chunk biome mismatch")
		#return false
		#
	##todo: entities !!
	#
	#if c1.square_datas.size() != c2.square_datas.size():
		#return false
		#
	#for x in range(0, c1.square_datas.size()):
		#if !compare_squares(c1.square_datas[x], c2.square_datas[x]):
			#return false
	#return true
	#
#func compare_squares(s1 : SquareData, s2 : SquareData) -> bool:
	#for property in s1.get_script().get_script_property_list():
		#if property.name.right(3) != ".gd":
			#if s1[property.name] != s2[property.name]:
				#print("property mismatch")
				#print(property.name)
				#print("s1")
				#print(s1[property.name])
				#print("s2")
				#print(s2[property.name])
				#return false
	#return true
	#
#func compare_stories(s1 : StoryData, s2 : StoryData) -> bool:
	#for property in s1.get_script().get_script_property_list():
		#if property.name.right(3) != ".gd":
			#if s1[property.name] != s2[property.name]:
				#print("property mismatch")
				#print(property.name)
				#print("s1")
				#print(s1[property.name])
				#print("s2")
				#print(s2[property.name])
				#return false
	#return true
		#
#func compare_entities(e1 : EntityData, e2 : EntityData) -> bool:
	#if e1.get_script() != e2.get_script():
		#print("different scripts")
		#print("e1")
		#print(e1)
		#print("e2")
		#print(e2)
		#return false
	#
	#for property in e1.get_script().get_script_property_list():
		#if property.name.right(3) != ".gd" && property.name != "inventory":
			#if e1[property.name] != e2[property.name]:
				#print("different properties")
				#print(property.name)
				#print("e1")
				#print(e1[property.name])
				#print("e2")
				#print(e2[property.name])
				#return false
	#
	#if !compare_inventories(e1.inventory, e2.inventory):
		#return false
	#return true
#
#func compare_inventories(i1 : InventoryData, i2:InventoryData):
	#if i1 == null:
		#if i2 == null:
			#return true
		#print("i1 is null, i2 is not")
		#return false
	#if i2 == null:
		#print("i2 is null, i1 is not")
		#return false
			#
	#if i1.slot_datas.size() != i2.slot_datas.size():
		#print("slot datas different size")
		#print(i1.slot_datas.size())
		#print(i2.slot_datas.size())
		#return false
	#
	#for x in range(0, i1.slot_datas.size()):
		#var s1 = i1.slot_datas[x]
		#var s2 = i2.slot_datas[x]
		#
		#if s1 == null:
			#if s2 == null:
				#pass
			#else:
				#print("slot %d in s1 was null but not null in s2" % [x])
				#return false
		#else:
			#if s2 == null:
				#print("slot %d in s2 was null but not null in s1" % [x])
				#return false
		#
		#if s1 != null && s2 != null:
			#if s1.quantity != s2.quantity:
				#return false
			#if s1.item_data.name != s2.item_data.name:
				#return false
	#return true
	#
#
##world size * world_size = total number of chunks
##chunk_size * chunk_size = total number of tiles in chunk
#func make_random_world(world_size: int, chunk_size:int) -> WorldData:
	#var rng = RandomNumberGenerator.new()
	#
	#rng.seed = hash("this blog participates in penis friday")
	#
	#var world = WorldData.new()
	#
	#world.world_seed = rng.seed
	#world.world_size = Vector2(world_size, world_size)
	#world.chunk_size = Vector2(chunk_size, chunk_size)
	#
	#var arr : Dictionary
	#
	#for x in range(0, world_size):
		#for y in range(0, world_size):
			#var chunk:ChunkData = make_random_chunk(rng, x, y, chunk_size)
			#arr[chunk.chunk_position] = chunk
			#
	#world.chunk_datas = arr
	#
	#return world
	#
#func make_random_chunk(rng:RandomNumberGenerator, x:int, y:int, size:int) -> ChunkData:
	#var chunk = ChunkData.new()
	#
	#chunk.chunk_position = Vector2(x, y)
	#chunk.chunk_size = Vector2(size, size)
	#
	#chunk.biome = rng.randi_range(0, 1)
	#var squareArr : Array[SquareData] = []
	#
	#for i in range(0, size):
		#for j in range(0, size):
			#squareArr.append(make_random_square(rng, i, j))
	#chunk.square_datas = squareArr
	#
	#return chunk
	#
#
#func make_random_square(rng:RandomNumberGenerator, x:int, y:int) -> SquareData:
	#var square = SquareData.new()
	#
	#square.chunk_location = Vector2(x, y)
	#square.elevation = rng.randi()
	#square.water_saturation = rng.randi()
	#square.fertility = rng.randi()
	#square.type = rng.randi_range(0, 3)
	#square.status = rng.randi_range(0, 2)
	##TODO: random object id + random inventory
	#return square
	#
