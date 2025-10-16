extends Area2D
#class_name ElevationHandler

# Possible bug with this design: if an entity loads in on a slope that might be weird

signal give_me_layer_please(needed_layer: int, method_to_send_layer:Callable)

@onready var water_detector: Area2D = $WaterDetector

var collision_box: CollisionShape2D

var current_map_layer:ElevationLayer = null
var current_elevation:int = 0

var onslope:bool = false
var slope_type: String = ""
var other_map_layer:ElevationLayer = null
var other_elevation:int = 0
var swimming: bool = false
var tile_type: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_child(0) is CollisionShape2D:
		collision_box = get_child(0)
	else:
		print("WAAAAAAAAHHHHHH ELEVATION HANDLER INSTANTIATED WITHOUT COLLIDER")
		self.queue_free()
	
func _process(_delta: float) -> void:
	if current_map_layer == null:
		give_me_layer_please.emit(current_elevation, Callable(self, "set_layer"))
	if Engine.get_process_frames() % 10 == 0 && current_elevation != null:
		## TODO: whenever we make footstep sounds, it might be pertinent
		## to change this value to be a bitmask of some kind-> that way i can store
		## an int instead of a string, and elevation slopes can be in conjuction
		## with a type value, like grass or dirt. or a Wet Value
		var tile_data:TileData = get_tile_below(current_map_layer)
		if tile_data:
			tile_type = get_tile_below(current_map_layer).get_custom_data("type")
		
func set_layer(layer:ElevationLayer) -> void:
	#print("layer set: ", layer.elevation)
	current_elevation = layer.elevation
	current_map_layer = layer

func entity_entered_slope(other_layer: ElevationLayer) -> void:
	print("layer slope entered: ", other_layer.elevation)
	onslope = true
	other_map_layer = other_layer
	other_elevation = other_layer.elevation
	set_parents_collision_mask(other_elevation, true)

func entity_exited_slope(new_layer:ElevationLayer) -> void:
	print("layer slope exit: ", new_layer.elevation)
	onslope = false
	set_parents_collision_mask(current_elevation, false)
	current_elevation = new_layer.elevation
	current_map_layer = new_layer
	set_parents_collision_mask(current_elevation, true)
	#print("player mask:", String.num_uint64(get_parent().collision_mask, 2))

func set_parents_collision_mask(target:int, val:bool)->void:
	# Layer collisions exist in layer 10 + elevation
	get_parent().set_collision_mask_value(target+10,val)
		
func configure_downslope(stair_layer: ElevationLayer) -> void: 
	var tile_data: TileData = get_tile_below(stair_layer)
	if tile_data == null || !tile_data.get_custom_data("type").contains("stair"):
		await get_tree().create_timer(.01).timeout
		tile_data = get_tile_below(stair_layer)
		#print("DIDNT FIND STAIR CASE FOUND:", tile_data," AT elevation:" , stair_layer.elevation, " and position: ", stair_layer.local_to_map(collision_box.global_position))
	if tile_data: 
		slope_type = tile_data.get_custom_data("type")
	print("slope type: ", slope_type)

func get_tile_below(layer: ElevationLayer) -> TileData:
	#print("global position: ", collision_box.global_position, " local to map: ", layer.local_to_map(collision_box.global_position))
	var tile_data:TileData = layer.get_cell_tile_data(layer.local_to_map(collision_box.global_position))
	return tile_data

func get_surronding_tiles_dir(dir: String, layer:TileMapLayer) -> Array[TileData]:
	var arr: Array[TileData] = []
	var vector_pos:Vector2i = layer.local_to_map(collision_box.global_position)
	
	if dir == "hstair":
		arr.append(layer.get_cell_tile_data(vector_pos + Vector2i.LEFT))
		arr.append(layer.get_cell_tile_data(vector_pos + Vector2i.RIGHT))
	if dir == "vstair":
		arr.append(layer.get_cell_tile_data(vector_pos + Vector2i.UP))
		arr.append(layer.get_cell_tile_data(vector_pos + Vector2i.DOWN))
	return arr
	
## Used for elevation changes
func _on_body_entered(body: Node2D) -> void:
	if body.get_parent() is ElevationLayer:
		body = body.get_parent()
		# Slopes are layer 2^9 = 256
		#print("entered a slope of elevation: ", body.elevation)
		configure_downslope(body)
		if body.elevation == current_map_layer.elevation:
			#this is a slope going down- should be this elevation - 1
			give_me_layer_please.emit(current_elevation-1, Callable(self,"entity_entered_slope"))
		else:
			entity_entered_slope(body)

func _on_body_exited(body: Node2D) -> void:
	if body.get_parent() is ElevationLayer:
		body = body.get_parent()
		if body.elevation == current_map_layer.elevation:
			#this is a slope going down- should be this elevation - 1
			give_me_layer_please.emit(current_elevation-1, Callable(self,"entity_exited_slope"))
		else:
			entity_exited_slope(body)
	
## Used for swimming in water
func _on_water_detector_body_entered(body: Node2D) -> void:
	if body.get_parent() is ElevationLayer: 
		body = body.get_parent()
		if body.elevation == current_map_layer.elevation:
			swimming = true

func _on_water_detector_body_exited(body: Node2D) -> void:
	if body.get_parent() is ElevationLayer: 
		body = body.get_parent()
		if body.elevation == current_map_layer.elevation:
			## check if we are still clipping some water
			if water_detector.overlaps_body(body):
				## we are still in the water 
				swimming = true
			else: 
				swimming = false
		
