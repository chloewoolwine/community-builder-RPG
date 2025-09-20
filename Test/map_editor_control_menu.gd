extends Control
# this is only meant to live in this scene- if you dare change these
@onready var world_manager: WorldManager = $"../../WorldManager"
@onready var file_dialog: FileDialog = $"../../FileDialog"
@onready var file_dialog_2: FileDialog = $"../../FileDialog2"
@onready var camera_2d: Camera2D = $"../../Camera2D"
@onready var trh: TerrainRulesHandler = $"../../WorldManager/TerrainRulesHandler"
@onready var temp_mousecast: Area2D = $"../../WorldManager/temp_mousecast"
@onready var tile_indicator: Indicator = $"../../TileIndicator"
@onready var world_saver: Node2D = $"../../WorldSaver"

@export var camera_zooms : Array[float]
var curr_zoom : int = 1

var paint: bool = false
var radius: int = 1
var paint_type: String = ""

func _ready() -> void:
	file_dialog.file_selected.connect(func(filename: String) -> void: world_manager.set_world_data(ResourceLoader.load(filename, "WorldData")))
	file_dialog_2.file_selected.connect(func(filename: String) -> void:
			#print("filename: ", filename) 
			if(!filename.ends_with(".tres")):
				filename = str(filename, ".tres")
			world_saver.save_world(world_manager._world_data, filename)
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
	radius += 1

func _on_little_pressed() -> void:
	radius -= 1
	if radius < 1:
		radius = 1

func _on_brush_pressed() -> void:
	paint = true

func _on_eraser_pressed() -> void:
	paint = false
#
#const POPLAR_POD = preload("res://Scenes/items/seeds/poplar_pod.tres")
#const THATCH_ROOF = preload("res://Scenes/items/build/thatch_roof.tres")
#const WOOD_WALL = preload("res://Scenes/items/build/wood_wall.tres")
#const WOOD_DOOR = preload("res://Scenes/items/build/wood_door.tres")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var mouse: Vector2 = world_manager.get_global_mouse_position()
		#world_manager.modify_tilemap(mouse, trh.get_topmost_layer_at_global_pos(mouse), "till")
		#temp_mousecast.global_position = mouse
		tile_indicator.global_position = mouse
		#var layer := trh.get_topmost_layer_at_global_pos(mouse)
		if paint:
			print("paint time")
			match paint_type:
				"grass":
					world_manager.modify_terrain(mouse, SquareData.SquareType.Grass)
				"stone":
					world_manager.modify_terrain(mouse, SquareData.SquareType.Rock)
				"soil":
					world_manager.modify_terrain(mouse, SquareData.SquareType.Dirt)
				"water":
					world_manager.change_water(mouse, 4)
				"sand":
					world_manager.modify_terrain(mouse, SquareData.SquareType.Sand)
				"dry":
					world_manager.change_water(mouse, 0)
			#if world_manager.check_placement_validity(tile_indicator, mouse, trh.get_topmost_layer_at_global_pos(mouse), WOOD_WALL):
				#world_manager.place_object(mouse, trh.get_topmost_layer_at_global_pos(mouse), WOOD_WALL)
		else:
			var objects := world_manager.get_objects_at_world_pos(mouse)
			for x in objects:
				if x != null:
					world_manager.destroy_object(x)

func _on_temp_mousecast_body_entered(body: Node2D) -> void:
	if body is InteractionHitbox:
		body.player_interact()

func _on_water_pressed() -> void:
	paint = true
	paint_type = "water"

func _on_sand_pressed() -> void:
	paint = true
	paint_type = "sand"

func _on_soil_pressed() -> void:
	paint = true
	paint_type = "soil"

func _on_grass_pressed() -> void:
	paint = true
	paint_type = "grass"

func _on_stone_pressed() -> void:
	paint = true
	paint_type = "stone"

func _on_dry_pressed() -> void:
	paint = true
	paint_type = "dry"
