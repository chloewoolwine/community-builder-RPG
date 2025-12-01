extends Node2D
class_name ElevationMask

signal freeing_self(me: ElevationMask)

@onready var masker: Sprite2D = $masker
@onready var mark: Sprite2D = $Mark

var debug: bool = true
var elevation: int
var loc: Vector2i
var masks: Array[Sprite2D]

func _ready() -> void:
	if elevation == 0:
		push_warning("ElevationMask created for elevation 0 or elevation not set")
		freeing_self.emit(self)
		self.queue_free()
	if debug:
		mark.visible = true
	else:
		mark.visible = false
	masks.push_front(masker)
	var old := elevation
	elevation = 0
	while old != elevation:
		increase_elevation()
	
func decrease_elevation() -> void:
	elevation = elevation - 1
	masks.pop_front().queue_free()
	if elevation == 0:
		freeing_self.emit(self)
		self.queue_free()

func increase_elevation() -> void:
	# IDK IF THIS WORKS !
	elevation = elevation + 1 
	var new := masker.duplicate()
	new.position.y = (elevation-1) * Constants.ELEVATION_Y_OFFSET
	add_child(new)
	masks.push_front(new)

func change_elevation_to(val:int) -> void:
	while val < elevation:
		increase_elevation()
	while val > elevation:
		decrease_elevation()
