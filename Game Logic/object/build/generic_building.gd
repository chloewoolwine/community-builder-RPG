extends Node
class_name GenericBuilding_unusable

var build_data: BuildData

var walls: Array[GenericWall]
var valid_building: bool
var bottom_right: Vector2i
var roof:String

func ready() -> void: 
	set_position_data()

func _on_child_entered_tree(node: Node) -> void:
	if node is GenericWall and node not in walls: 
		walls.append(node as GenericWall)
		build_data.walls.append(node.object_id)
		set_position_data()

func remove_wall(node: GenericWall) -> void: 
	walls.erase(node)
	build_data.walls.erase(node.object_data)

func merge_buildings(arr: Array[GenericBuilding_unusable]) -> void: 
	var object_atlas: ObjectAtlas = get_parent()
	for other in arr:
		var o_data := other.build_data
		for wall in o_data.walls: #wall data in building location
			if wall not in build_data.walls:
				build_data.walls.append(wall)
		for wall in other.walls: #wall data in object space
			if wall not in walls:
				wall.reparent(self)
		object_atlas.remove_building(other.build_data)
		other.queue_free()

# loops through everything to find the top left position- 
# this will keep buildings from duplicating
func set_position_data() -> void: 
	var top_left_chunk := Vector2i.MAX
	var top_left_pos := Vector2i.MAX
	var top_right_chunk := Vector2i.MIN
	var top_right_pos := Vector2i.MIN
	for wall in walls: 
		if wall.object_data.chunk < top_left_chunk:
			top_left_chunk = wall.object_data.chunk
			top_left_pos = wall.object_data.position
		if wall.object_data.position < top_left_pos:
			top_left_pos = wall.object_data.position 
		if wall.object_data.chunk > top_right_chunk: 
			top_right_chunk = wall.object_data.chunk
			top_right_pos = wall.object_data.position
		if wall.object_data.position > top_right_pos:
			top_right_pos = wall.object_data.position 
