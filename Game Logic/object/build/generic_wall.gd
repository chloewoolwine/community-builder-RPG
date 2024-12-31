extends Node2D
class_name GenericWall
const GENERIC_BUILDING = preload("res://Scenes/object/build/generic_building.tscn")

@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox
@onready var neighbor_searcher: Area2D = $NeighborSearcher
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var object_id: String # wall types
@export var sprite_bases: Array[Texture2D]

## Object Data information 
var object_data: ObjectData
var is_door: bool
var is_window: bool
#TODO: colors and stuff

var neighbors: Array[GenericWall] #0 = up, 1 = right, 2 = down, 3 = left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_hitbox.set_to_wall(true)
	neighbor_searcher.set_collision_mask_value(interaction_hitbox.current_elevation + 10, true)
	neighbors = [null,null,null,null]
	var overlaps := neighbor_searcher.get_overlapping_bodies()
	for overlap in overlaps: 
		var wall:Node2D = overlap.get_parent()
		if wall is GenericWall && overlap:
			if wall.global_position.x == global_position.x:
				if wall.global_position.y < global_position.y:
					#up 
					neighbors[0] = wall as GenericWall
				else: 
					#down 
					neighbors[2] = wall as GenericWall
			elif wall.global_position.y == global_position.y:
				if wall.global_position.x < global_position.x: 
					#left 
					neighbors[3] = wall as GenericWall
				else: 
					neighbors[1] = wall as GenericWall
	if get_parent() is not GenericBuilding:
		determine_building()
	determine_sprite()
	if get_parent() is GenericBuilding:
		check_neighbor_homogeny()
	interaction_hitbox.player_interacted.connect(destroy)
	for tag in object_data.object_tags.keys(): 
		if tag == "door":
			is_door = true
		if tag == "window":
			is_window = true
	
func check_neighbor_homogeny() -> void:
	# checking to make sure all neighbors have the same building
	var buildings:Array[GenericBuilding] = []
	var my_building: GenericBuilding = get_parent()
	for neighbor in neighbors:
		if neighbor != null:
			var n_parent := neighbor.get_parent()
			if n_parent is ObjectAtlas:
				neighbor.reparent(my_building)
			elif n_parent is GenericBuilding and n_parent != my_building:
				#other building located
				buildings.append(n_parent)
	if buildings.size() > 0: 
		my_building.merge_buildings(buildings)

func determine_building() -> void: 
	#ask neighbors for parent
	if neighbors[0] != null: 
		var building := neighbors[0].get_building()
		reparent(building)
		return
	if neighbors[3] != null:
		var building := neighbors[0].get_building()
		reparent(building)
		return
	if neighbors[1] != null:
		var building := neighbors[0].get_building()
		reparent(building)
		return
	if neighbors[2] != null:
		var building := neighbors[0].get_building()
		reparent(building)
		return
	# if we're back here, we are alone and there is no building

func determine_sprite() -> void:
	#TODO: this logic
	sprite_2d.texture = sprite_bases[0] 

func get_building() -> GenericBuilding:
	var parent := get_parent()
	if parent is GenericBuilding:
		return parent
	var new_building := GENERIC_BUILDING.instantiate()
	var build_data := BuildData.new()
	# tell the object atlas about our new friend
	parent.new_building(build_data, new_building)
	#add new friend to the scene tree
	new_building.reparent(parent)
	#make self a part of new friend
	self.reparent(new_building)
	return new_building

func destroy() -> void: 
	if neighbors[0] != null: 
		neighbors[0].neighbors[2] = null 
	if neighbors[2] != null:
		neighbors[2].neighbors[0] = null
	if neighbors[1] != null:
		neighbors[1].neighbors[3] = null
	if neighbors[3] != null:
		neighbors[3].neighbors[1] = null
	if get_parent() is GenericBuilding:
		get_parent().remove_wall(self)
	self.queue_free()
