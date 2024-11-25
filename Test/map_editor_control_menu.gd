extends Control
# this is only meant to live in this scene- if you dare change these
@onready var world_manager: WorldManager = $"../../WorldManager"
@onready var file_dialog: FileDialog = $"../../FileDialog"
@onready var file_dialog_2: FileDialog = $"../../FileDialog2"
@onready var camera_2d: Camera2D = $"../../Camera2D"

@export var camera_zooms : Array[float]
var curr_zoom : int = 1

var paint: bool = false
var erase: bool = false

func _ready() -> void:
	file_dialog.file_selected.connect(func(filename: String) -> void: world_manager.set_world_data(ResourceLoader.load(filename, "WorldData")))
	file_dialog_2.file_selected.connect(func(filename: String) -> void:
			#print("filename: ", filename) 
			if(!filename.ends_with(".tres")):
				filename = str(filename, ".tres")
			world_manager.save_world(filename)
			camera_2d.can_move = true)

func _on_save_pressed() -> void:
	file_dialog_2.visible = true
	camera_2d.can_move = false

func _on_load_pressed() -> void:
	file_dialog.visible = true
	file_dialog.invalidate()

func _on_zoomin_pressed() -> void:
	if curr_zoom < camera_zooms.size()-1:
		curr_zoom = curr_zoom + 1

func _on_zoomout_pressed() -> void:
	if curr_zoom > 0:
		curr_zoom = curr_zoom - 1

func _on_big_pressed() -> void:
	pass # Replace with function body.

func _on_little_pressed() -> void:
	pass # Replace with function body.

func _on_brush_pressed() -> void:
	pass # Replace with function body.

func _on_eraser_pressed() -> void:
	pass # Replace with function body.
