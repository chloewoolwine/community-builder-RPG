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
@onready var pollution_grass: TileMapDual = $PollutionGrass
@onready var decor: TileMapLayer = $Decor
@onready var water_mapper: TileMapLayer = $WaterMapper
@onready var higher_elevation_warner: TileMapLayer = $HigherElevationWarner

@onready var arr:Array[TileMapDual] = [base, pond, sand, grass, stone, pollution_grass]

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
	#self.tile_set = self.tile_set.duplicate()
	#self.tile_set.set_physics_layer_collision_mask(0,0)
	base.tile_set = base.tile_set.duplicate()
	## how this works for future reference
	## for elevation 0, this will eval to 1000000000 (only the 10th bit flipped) 
	## that's why in the elevation handler you can do entity.set_collision_mask_value(current_elevation+10)
	## as set_collision_mask_value changes the nth bit 
	base.tile_set.set_physics_layer_collision_layer(0, 1 << (elevation + 9))
	higher_elevation_warner.tile_set = higher_elevation_warner.tile_set.duplicate()
	higher_elevation_warner.tile_set.set_physics_layer_collision_layer(0, 1 << (elevation + 9))
	print("elevation: ", elevation)
	print("physics layer ", elevation, " collision layer: ", base.tile_set.get_physics_layer_collision_layer(0))
	## CHLOE LOOK AT ME 
	## WHEN YOU ADD A NEW LAYER. GO INTO THE ELEVATION. AND ADD IT THERE TOO. OK?
	## OR ELSE !!!!!
	## "world source id" is the source id in the master tileset- mapper.tres
	## World source id doesn't matter for pond because it reads from its own map
	pond.world_source_id = 0 
	sand.world_source_id = 2
	grass.world_source_id = 4
	pollution_grass.world_source_id = 1

func change_square(_data: SquareData, overall_location: Vector2i) -> void:
	#print("modifying loaded square at runtime")
	grass.erase_tile(overall_location)
	stone.erase_tile(overall_location)
	base.erase_tile(overall_location)
	sand.erase_tile(overall_location)
	pollution_grass.erase_cell(overall_location)
	pond.just_erase_tile(overall_location)
	if _data.elevation == elevation:
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
				base.fill_tile(overall_location, 0)
				#print("filled grass")
				if _data.pollution > 2:
					pollution_grass.fill_tile(overall_location)
				else:
					grass.fill_tile(overall_location, 0)
			SquareData.SquareType.Rock:
				#print("filled rocj")
				base.fill_tile(overall_location)
				stone.fill_tile(overall_location)
			SquareData.SquareType.Sand:
				#print("filled sand")
				base.fill_tile(overall_location)
				sand.fill_tile(overall_location)
	if _data.object_data && _data.object_data.size() > 0:
		var floor_type := _data.object_data[0]
		if floor_type != null:
			if floor_type.object_id == "till":
				till.set_cell(overall_location, 0, Vector2i(_data.water_saturation,0))

func build_base_of(_data: SquareData, overall_location:Vector2i) -> void:
	#print("build_base_of tile: ", overall_location, " type: ", _data.type)
	#match _data.type:
		#SquareData.SquareType.Dirt:
			#base.fill_tile(overall_location)
		#SquareData.SquareType.Grass:
			#base.fill_tile(overall_location)
		## TODO: these two should be replaced with sand + stone bases respectively 
		#SquareData.SquareType.Rock:
			#base.fill_tile(overall_location)
		#SquareData.SquareType.Sand:
			#base.fill_tile(overall_location)
	base.fill_tile(overall_location)
	add_elevation_barrier(overall_location)
	
func delete_square(overall_location: Vector2i) -> void:
	for layer in arr:
		layer.just_erase_tile(overall_location)
	#pond.set_cell(overall_location)
	till.set_cell(overall_location)
	higher_elevation_warner.set_cell(overall_location)

func update_specific_pixel(overall_location: Vector2i, _data:SquareData) -> void:
	till.set_cell(overall_location, 0, Vector2i(_data.water_saturation,0))

func add_grass(overall_location: Vector2i, pollution: int) -> void: 
	grass.fill_tile(overall_location)
	if pollution > 2:
		pollution_grass.fill_tile(overall_location)

func remove_grass(overall_location: Vector2i) -> void: 
	grass.erase_tile(overall_location)
	pollution_grass.erase_tile(overall_location)

func till_square(overall_location: Vector2i, square: SquareData) -> void: 
	till.set_cell(overall_location, 0, Vector2i(square.water_saturation,0))

func remove_till(overall_location: Vector2i) -> void:
	till.set_cell(overall_location)

func remove_base(overall_location: Vector2i) -> void: 
	base.erase_tile(overall_location)
	higher_elevation_warner.set_cell(overall_location, -1)

func add_base(overall_location: Vector2i) -> void:
	base.fill_tile(overall_location)

func add_elevation_barrier(overall_location: Vector2i) -> void: 
	higher_elevation_warner.set_cell(overall_location, 0, Vector2i.ZERO)

func remove_elevation_barrier(overall_location: Vector2i) -> void: 
	higher_elevation_warner.set_cell(overall_location, -1)
