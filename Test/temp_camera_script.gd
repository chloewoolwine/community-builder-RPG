extends Camera2D
@export var speed: int = 10
@onready var control: Control = $"../CanvasLayer/Control"
var can_move:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.zoom.x = control.camera_zooms[control.curr_zoom]
	self.zoom.y = control.camera_zooms[control.curr_zoom]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.zoom.x = control.camera_zooms[control.curr_zoom]
	self.zoom.y = control.camera_zooms[control.curr_zoom]
	
	var input: Vector2 = Vector2.ZERO
	if Input.is_action_pressed('down'):
		input.y = 1
	elif Input.is_action_pressed('up'):
		input.y = -1
	else:
		input.y = 0 
	if Input.is_action_pressed('right'):
		input.x = 1
	elif Input.is_action_pressed('left'):
		input.x = -1
	else:
		input.x = 0 
	
	#fix diagonals
	if Input.is_action_just_released('up'):
		input.y = 0
	if Input.is_action_just_released('right'):
		input.x = 0
	if Input.is_action_just_released('left'):
		input.x = 0
	if Input.is_action_just_released('down'):
		input.y = 0
	if can_move:
		position += input * speed
