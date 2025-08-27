extends TileMapLayer
class_name ElevationLayer

#NOTE: in order for cliff collisions to work *correctly,* the top layer AND the bottom layer
#need to have colliders there. 
@export var elevation:int = 0

#@onready var cliff_markers: TileMapLayer = $CliffMarkers
@onready var base: TileMapDual = $Base
# Water shader ideas: 
# https://www.youtube.com/watch?v=pGOLstWBCDA
# https://godotshaders.com/shader/pixel-art-water/
@onready var pond: TileMapDual = $Pond
@onready var sand: TileMapDual = $Sand
@onready var till: TileMapLayer = $Till
@onready var grass: TileMapDual = $Grass
@onready var stone: TileMapDual = $Stone
@onready var decor: TileMapLayer = $Decor
@onready var water_mapper: TileMapLayer = $WaterMapper

@onready var arr:Array[TileMapDual] = [base, pond, sand, grass, stone]

var moisture_gradient_map: Image
# real tilemap coord where gradient texture should be aligned into 
var gradient_top_left_pos: Vector2i
var chunk_atlas: Dictionary
var top_left_chunk: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_physics_data()

## Sets physics data based on [member elevation] 
func set_physics_data() -> void:
	self.tile_set = self.tile_set.duplicate()
	self.tile_set.set_physics_layer_collision_mask(0,0)
	var x : int = 0
	for layer in arr:
		#make tileset unique- this is to set the collision layers properly
		if (layer.tile_set == null):
			layer.tile_set = self.tile_set
		layer.tile_set = layer.tile_set.duplicate()
		#clear old layer
		layer.tile_set.set_physics_layer_collision_mask(0,0)
		layer.tile_set.set_physics_layer_collision_layer(0, 0b1 << elevation+9)
		layer.world_source_id = x
		x = x + 1
	## World source id doesn't matter for pond because it reads from its own map
	pond.world_source_id = 0 

func change_square(_data: SquareData, overall_location: Vector2i) -> void:
	#print("modifying loaded square at runtime")
	grass.erase_tile(overall_location)
	stone.erase_tile(overall_location)
	base.erase_tile(overall_location)
	sand.erase_tile(overall_location)
	pond.just_erase_tile(overall_location)
	set_square(_data, overall_location)
		
func set_square(_data: SquareData, overall_location: Vector2i)-> void:
	#print("Setting top layer of ", _data.elevation, " loc: ", _data.location_in_chunk, " as type ", _data.type)
	if _data.elevation != elevation:
		push_warning("Elevation", elevation, " recieved a set_square request for SquareData: ", _data.location_in_chunk, " elevation: ", _data.elevation)
		return
	if _data.water_saturation > 3: # It's a water tile/deep water
		#print("making water tile")
		pond.fill_tile(overall_location)
	else:
		#print("filling stuff")
		match _data.type:
			SquareData.SquareType.Dirt:
				#print("filled base")
				if _data.pollution > 1:
					base.fill_tile(overall_location, 0) #TODO: we gon slap another texture on top
				else:
					base.fill_tile(overall_location)
			SquareData.SquareType.Grass:
				#print("filled grass")
				if _data.pollution > 1:
					base.fill_tile(overall_location, 0)
					grass.fill_tile(overall_location, 0)
				else:
					base.fill_tile(overall_location)
					grass.fill_tile(overall_location)
			SquareData.SquareType.Rock:
				#print("filled rocj")
				base.fill_tile(overall_location)
				stone.fill_tile(overall_location)
			SquareData.SquareType.Sand:
				#print("filled sand")
				base.fill_tile(overall_location)
				sand.fill_tile(overall_location)
	#grass.fill_tile(overall_location)
	if _data.object_data && _data.object_data.size() > 0:
		var floor_type := _data.object_data[0]
		if floor_type != null:
			if floor_type.object_id == "till":
				till.set_cell(overall_location, 0, Vector2i(_data.water_saturation,0))

func build_base_of(_data: SquareData, overall_location:Vector2i) -> void:
	#print("build_base_of tile: ", overall_location, " type: ", _data.type)
	match _data.type:
		SquareData.SquareType.Dirt:
			base.fill_tile(overall_location)
		SquareData.SquareType.Grass:
			base.fill_tile(overall_location)
		# TODO: these two should be replaced with sand + stone bases respectively 
		SquareData.SquareType.Rock:
			base.fill_tile(overall_location)
		SquareData.SquareType.Sand:
			base.fill_tile(overall_location)
	
func delete_square(overall_location: Vector2i) -> void:
	for layer in arr:
		layer.just_erase_tile(overall_location)
	#pond.set_cell(overall_location)
	till.set_cell(overall_location)
## we can have a layer for elevation changes (base) and then a layer for ponds
## dont' have to worry about it until terrain edits can happen
## on layer 0, base tiles are just replaced with water tiles
## yippie :3 

func set_biome(biome: int) -> void:
	for layer in arr:
		layer.source_id = biome
	if elevation == 0:
		base.source_id = 1
	pond.source_id = 0 
	
func update_gradient_map_pos(new_pos: Vector2i) -> void:
	gradient_top_left_pos = new_pos
	base.material.set_shader_parameter("tint_pos", new_pos)
	if(gradient_top_left_pos != null):
		base.material.set_shader_parameter("tint_pos", gradient_top_left_pos)

func build_gradient_maps(chunks: Dictionary, top_left: Vector2i) -> void:
	pass
	#var size: int = chunks.values()[0].chunk_size.x
	#moisture_gradient_map = Image.create(size*3, size*3, false, Image.FORMAT_RGBA8) # RGB format for now? 
	##TODO: there's probably some kind of optimization here if I construct a PackedByteArray instead of doing set_pixel, but idk how to do it yet
	##print(moisture_gradient_map.get_size())
	#for x in range(top_left.x, top_left.x + 3):
		#for y in range(top_left.y, top_left.y + 3):
			#var chunk: ChunkData = chunks[Vector2i(x, y)]
			#var chu_x: int = abs(x - top_left.x) * size
			#var chu_y: int = abs(y - top_left.y) * size
			#for sub_x in range(size):
				#var img_x: int = chu_x + sub_x
				#for sub_y in range(size):
					#var img_y: int = chu_y + sub_y
					#moisture_gradient_map.set_pixel(img_x, img_y, Color.BLACK * chunk.square_datas[Vector2i(sub_x, sub_y)].water_saturation/5)
					##print("pixel x: ", img_x, " pixel y", img_y, " mositure: ", chunk.square_datas[Vector2i(sub_x, sub_y)].water_saturation)
	## moisture_gradient_map.resize(size*64,size*64,Image.INTERPOLATE_NEAREST)
	## TODO: refractor this for better performance? 
	#till.material.set("shader_parameter/mod_color_tex", ImageTexture.create_from_image(moisture_gradient_map))
	##print("top_left_corner_chunk: ", top_left)
	#var top_left_corner_pos:Vector2 = to_global(map_to_local(chunks[top_left].chunk_position * size))
	##print("top_left_corner_pos = ", top_left_corner_pos)
	#gradient_top_left_pos = top_left_corner_pos
	#chunk_atlas = chunks
	#top_left_chunk = top_left
	#print("resize")
	##moisture_gradient_map.resize(size*3*64, size*3*64, Image.INTERPOLATE_BILINEAR)
	#print("resize over")
	#till.material.set("shader_parameter/global_corner_pos", top_left_corner_pos)

func update_specific_pixel(overall_location: Vector2i, _data:SquareData) -> void:
	till.set_cell(overall_location, 0, Vector2i(_data.water_saturation,0))

func add_grass(overall_location: Vector2i) -> void: 
	grass.fill_tile(overall_location)

func remove_grass(overall_location: Vector2i) -> void: 
	grass.erase_tile(overall_location)

func till_square(overall_location: Vector2i, square: SquareData) -> void: 
	till.set_cell(overall_location, 0, Vector2i(square.water_saturation,0))

func remove_till(overall_location: Vector2i) -> void:
	till.set_cell(overall_location)
