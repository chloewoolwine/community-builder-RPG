extends Node2D
class_name GenericWall

#object_removed and @object_data are both REQUIRED for objects to Work

signal remove_my_decor(wall: GenericWall)
signal object_removed(wall_destroyed: ObjectData)

@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox
@onready var neighbor_searcher: Area2D = $NeighborSearcher
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var object_id: String # wall types
@export var sprite_bases: Array[Texture2D]

## Object Data information 
var object_data: ObjectData
var is_door: bool
var is_window: bool
var has_decor: bool
#TODO: colors and stuff

var neighbors: Array[GenericWall] #0 = up, 1 = right, 2 = down, 3 = left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_hitbox.set_to_wall(true)
	neighbors = [null,null,null,null]
	interaction_hitbox.player_interacted.connect(check_for_destroy)
	for tag:String in object_data.object_tags.keys(): 
		if tag == "door":
			is_door = true
			interaction_hitbox.set_to_wall(false, true)
		if tag == "window":
			is_window = true
	#print("wall placed, chunk: ", object_data.chunk, " position: ", object_data.position)
	
func _physics_process(_delta: float) -> void:
	var overlaps := neighbor_searcher.get_overlapping_bodies()
	for overlap in overlaps: 
		var wall:Node2D = overlap.get_parent()
		if wall != self and wall is GenericWall and wall not in neighbors:
			#print("wall at= ", object_data.position, "found new neighbor= ", wall.object_data.position)
			check_wall_position(wall)
	determine_sprite()

func check_wall_position(wall: GenericWall) -> void: 
	var other_chunk := wall.object_data.chunk
	var other_pos := wall.object_data.position
	var self_combined := object_data.position + (object_data.chunk * 32)
	var other_combined := other_pos + (other_chunk * 32)
	#print(" chunk: ", object_data.chunk, " position: ", object_data.position)
	#print(" chunk: ", other_chunk, " position: ", other_pos)
	if other_combined.x == self_combined.x:
		if other_combined.y < self_combined.y:
			#up 
			#print("wall is up")
			neighbors[0] = wall
			wall.neighbors[2] = self
		else: 
			#down 
			#print("wall is down")
			neighbors[2] = wall
			wall.neighbors[0] = self
	elif other_combined.y == self_combined.y:
		if other_combined.x < self_combined.x: 
			#left 
			#print("wall is left")
			neighbors[3] = wall
			wall.neighbors[1] = self
		else: 
			#print("wall is right")
			neighbors[1] = wall
			wall.neighbors[3] = self

func check_for_destroy() -> bool: 
	if is_door or is_window or has_decor:
		remove_my_decor.emit()
		return false
	for neighbor in neighbors:
		if neighbor.is_door:
			return false
	destroy()
	return true

func destroy() -> void: 
	object_removed.emit(object_data)
	if neighbors[0]:
		neighbors[0].remove_neighbor(2)
	if neighbors[2]:
		neighbors[2].remove_neighbor(0)
	if neighbors[1]:
		neighbors[1].remove_neighbor(3)
	if neighbors[3]:
		neighbors[1].remove_neighbor(3)
	self.queue_free()

func remove_neighbor(neighbor: int) -> void: 
	neighbors[neighbor] = null

const texture_dict: Dictionary = {
	0b0000 : 0, # middle
	0b1111 : 1, # up right down left
	0b0111 : 2, # right down left 
	0b1110 : 3, # up right down
	0b1101 : 4, # up right left
	0b1011 : 5, # up down left
	0b0011 : 6, # down left 
	0b1100 : 7, # up right 
	0b1001 : 8, # up left 
	0b0110 : 9, # right down 
	0b0100 : 10, # right
	0b0101 : 10, # right left 
	0b0001 : 10, # left 
	0b1000 : 11, # up 
	0b1010 : 11, # up down
	0b0010 : 11, # down
}

func determine_sprite() -> void:
	 #0 = up, 1 = right, 2 = down, 3 = left
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
	sprite_2d.texture = sprite_bases[texture_dict[mask]]


# NPCs might be able to slam the door in your face. maybe not a bad idea. 
func _on_neighbor_searcher_body_entered(body: Node2D) -> void:
	if body is Player and is_door:
		interaction_hitbox.set_to_wall(false)
		 # Replace with function body.

func _on_neighbor_searcher_body_exited(_body: Node2D) -> void:
	interaction_hitbox.set_to_wall(true)
