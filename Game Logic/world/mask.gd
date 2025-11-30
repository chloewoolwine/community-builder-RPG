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
	#masks.push_front(masker)
	#masker.position.y = 0
	#var prev := elevation
	elevation = elevation
	#increase_elevation(prev)
	#for x in range(0, elevation):
		#var new := masker.duplicate()
		#new.position.y = (x+1) * Constants.ELEVATION_Y_OFFSET
		#masks.push_front(new)

func decrease_elevation(val: int = 1) -> void:
	elevation = elevation - val
	for x in range(0, val):
		masks.pop_front().queue_free()
	if elevation == 0:
		freeing_self.emit(self)
		self.queue_free()

func increase_elevation(val: int = 1) -> void:
	# IDK IF THIS WORKS !
	for x in range(elevation, elevation + val):
		var new := masker.duplicate()
		new.position.y = (x+1) * Constants.ELEVATION_Y_OFFSET
		add_child(new)
		masks.push_front(new)
	elevation = elevation + val

func change_elevation_to(val: int) -> void: 
	if val == elevation:
		return
	if val > elevation:
		increase_elevation(val - elevation)
	if val < elevation:
		decrease_elevation(elevation - val)
