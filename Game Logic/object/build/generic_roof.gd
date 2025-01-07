extends Node2D
class_name GenericRoof
#will have one generic roof node for each tile in a building, they all live in slot 2 
signal kill_all_connected_roofs(roof: GenericRoof)

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var object_id: String # wall types
@export var sprites: Array[Texture2D]

var object_data:ObjectData
var walls: Array[GenericWall] #all walls connected to this building
var roof_squares: Dictionary #the "roof square" assigned to this roof- determines tile
# if the roof square is 3x any amount, this is an up and down roof
# otherwise it's side to side. dictionary from vector2i -> GenericRoof

func _ready() -> void:
	determine_tile()

func destroy() -> void:
	kill_all_connected_roofs.emit()
	self.queue_free()

func determine_tile() -> void:
	sprite_2d.texture = sprites[0]
