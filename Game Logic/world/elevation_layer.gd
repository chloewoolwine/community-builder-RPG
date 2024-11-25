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
@onready var till: TileMapDual = $Till
@onready var grass: TileMapDual = $Grass
@onready var stone: TileMapDual = $Stone
@onready var decor: TileMapLayer = $Decor
@onready var water_mapper: TileMapLayer = $WaterMapper

@onready var arr:Array[TileMapDual] = [base, pond, sand, till, grass, stone]

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
	pond.biome_source_id = 1 
		
func set_square(_data: SquareData, overall_location: Vector2i)-> void:
	#print("Setting top layer of ", _data.elevation, " loc: ", _data.location_in_chunk, " as type ", _data.type)
	if _data.elevation != elevation:
		push_warning("Elevation", elevation, " recieved a set_square request for SquareData: ", _data.location_in_chunk, " elevation: ", _data.elevation)
		return
	if _data.water_saturation > 3: # It's a water tile/deep water
		#print("making water tile")
		pond.fill_tile(overall_location)
	else:
		match _data.type:
			SquareData.SquareType.Dirt:
				#print("filled base")
				base.fill_tile(overall_location)
			SquareData.SquareType.Grass:
				base.fill_tile(overall_location)
				grass.fill_tile(overall_location)
			SquareData.SquareType.Rock:
				base.fill_tile(overall_location)
				stone.fill_tile(overall_location)
			SquareData.SquareType.Sand:
				base.fill_tile(overall_location)
				sand.fill_tile(overall_location)

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
## we can have a layer for elevation changes (base) and then a layer for ponds
## dont' have to worry about it until terrain edits can happen
## on layer 0, base tiles are just replaced with water tiles
## yippie :3 

func set_biome(biome: int) -> void:
	for layer in arr:
		layer.source_id = biome
	if elevation == 0:
		base.source_id = 1
	pond.source_id = 1 

func build_gradient_maps(chunks: Dictionary, bottom_coord: Vector2i) -> void:
	
	for key in chunks.keys():
		pass
		
