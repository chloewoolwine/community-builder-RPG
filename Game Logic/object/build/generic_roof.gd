extends Node2D
class_name GenericRoof
#will have one generic roof node for each tile in a building, they all live in slot 2 
signal kill_all_connected_roofs(roof: GenericRoof)

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var neighbor_searcher: Area2D = $NeighborSearcher

@export var object_id: String # wall types
@export var sprites: Array[Texture2D]

var object_data:ObjectData
var walls: GenericWall # Wall connected to this roof, if any 
var neighbors: Array[GenericRoof]  #0 = up, 1 = right, 2 = down, 3 = left
	
func _ready() -> void:
	neighbors = [null, null, null, null]

func destroy() -> void:
	kill_all_connected_roofs.emit()
	self.queue_free()

const texture_dict: Dictionary = {
	0b0000 : 0, # middle
	0b1111 : 0, # up right down left
	0b0111 : 8, # right down left 
	0b1110 : 2, # up right down
	0b1101 : 4, # up right left
	0b1011 : 6, # up down left
	0b0011 : 7, # down left 
	0b1100 : 3, # up right 
	0b1001 : 5, # up left 
	0b0110 : 1, # right down 
	0b0100 : 0, # right
	0b0101 : 0, # right left 
	0b0001 : 0, # left 
	0b1000 : 0, # up 
	0b1010 : 0, # up down
	0b0010 : 0, # down
}

func determine_tile() -> void:
	sprite_2d.texture = sprites[0]
	# there IS a better way to do this, im just an idiot C: 
	var mask := 0b0000
	if neighbors[0]:
		mask = mask | 0b1000
	if neighbors[1]:
		mask = mask | 0b0100
	if neighbors[2]:
		mask = mask | 0b0010
	if neighbors[3]:
		mask = mask | 0b0001
	sprite_2d.texture = sprites[texture_dict[mask]]

func _on_neighbor_searcher_area_entered(area: Area2D) -> void:
	if area.get_parent() is GenericRoof:
		check_roof_position(area.get_parent())
	determine_tile()

func check_roof_position(roof: GenericRoof) -> void: 
	var other_chunk := roof.object_data.chunk
	var other_pos := roof.object_data.position
	var self_combined := object_data.position + (object_data.chunk * 32)
	var other_combined := other_pos + (other_chunk * 32)
	print(" chunk: ", object_data.chunk, " position: ", object_data.position)
	print(" chunk: ", other_chunk, " position: ", other_pos)
	if other_combined.x == self_combined.x:
		if other_combined.y < self_combined.y:
			#up 
			#print("wall is up")
			neighbors[0] = roof
			roof.neighbors[2] = self
		else: 
			#down 
			#print("wall is down")
			neighbors[2] = roof
			roof.neighbors[0] = self
	elif other_combined.y == self_combined.y:
		if other_combined.x < self_combined.x: 
			#left 
			#print("wall is left")
			neighbors[3] = roof
			roof.neighbors[1] = self
		else: 
			#print("wall is right")
			neighbors[1] = roof
			roof.neighbors[3] = self
	roof.determine_tile()
	
