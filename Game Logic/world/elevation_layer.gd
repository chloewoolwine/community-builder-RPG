extends TileMapLayer
class_name ElevationLayer

#NOTE: in order for cliff collisions to work *correctly,* the top layer AND the bottom layer
#need to have colliders there. 
@export var elevation:int = 0

#@onready var cliff_markers: TileMapLayer = $CliffMarkers
@onready var base: TileMapDual = $Base
@onready var pond: TileMapDual = $Pond
@onready var sand: TileMapDual = $Sand
@onready var till: TileMapDual = $Till
@onready var grass: TileMapDual = $Grass
@onready var stone: TileMapDual = $Stone
@onready var decor: TileMapLayer = $Decor

@onready var arr:Array[TileMapLayer] = [base, pond, sand, till, grass, stone, decor]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_physics_data()

## Sets physics data based on [member elevation] 
func set_physics_data() -> void:
	self.tile_set = self.tile_set.duplicate()
	self.tile_set.set_physics_layer_collision_mask(0,0)
	for layer in arr:
		#make tileset unique- this is to set the collision layers properly
		if (layer.tile_set == null):
			layer.tile_set = self.tile_set
		layer.tile_set = layer.tile_set.duplicate()
		#clear old layer
		layer.tile_set.set_physics_layer_collision_mask(0,0)
		layer.tile_set.set_physics_layer_collision_layer(0, 0b1 << elevation+9)
		
func set_square(_data: SquareData, overall_location: Vector2i)-> void:
	base.fill_tile(overall_location)
	
func delete_square(overall_location: Vector2i) -> void:
	base.erase_tile(overall_location)
## we can have a layer for elevation changes (base) and then a layer for ponds
## dont' have to worry about it until terrain edits can happen
## on layer 0, base tiles are just replaced with water tiles
## yippie :3 
