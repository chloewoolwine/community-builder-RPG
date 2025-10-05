extends Node2D
class_name ElevationMask

@onready var masker: Sprite2D = $masker
@onready var mark: Sprite2D = $Mark

var chunk: Vector2i
var debug: bool = false
var elevation: int

var masks: Array[Sprite2D]

func _ready() -> void:
	if chunk == null:
		push_warning("ElevationMask spawned with no chunk. Killing self.")
		self.queue_free()
	if elevation == 0:
		push_warning("ElevationMask created for elevation 0 or elevation not set")
	if debug:
		mark.visible = true
	else:
		mark.visible = false
	masks.push_front(masker)
	for x in range(1, elevation):
		var new := masker.duplicate()
		new.transform.y = x * Constants.ELEVATION_Y_OFFSET
		masks.push_front(new)

func unload_mask(unloading_chunk: Vector2i) -> void: 
	if unloading_chunk == chunk:
		self.queue_free()

func decrease_elevation() -> void:
	elevation = elevation - 1 
	masks.pop_front()

func increase_elevation() -> void:
	elevation = elevation + 1
	var new := masker.duplicate()
	new.transform.y = elevation * Constants.ELEVATION_Y_OFFSET
	masks.push_front(new)
