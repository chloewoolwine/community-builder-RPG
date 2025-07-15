extends Control
@onready var object_atlas: ObjectAtlas = $"../../WorldManager/TerrainRulesHandler/ObjectAtlas"
@onready var world_manager: WorldManager = $"../../WorldManager"
@onready var player: Player = $"../../WorldManager/TerrainRulesHandler/ObjectAtlas/EntityManager/Player"
@onready var lighting: CalendarManager = $"../../StoryManager/Lighting"

@onready var label: Label = $PanelContainer/VBoxContainer/Label
@onready var label_2: Label = $PanelContainer/VBoxContainer/Label2
@onready var label_3: Label = $PanelContainer/VBoxContainer/Label3
@onready var label_4: Label = $PanelContainer/VBoxContainer/Label4
@onready var label_5: Label = $PanelContainer/VBoxContainer/Label5
@onready var label_6: Label = $PanelContainer/VBoxContainer/Label6
@onready var label_7: Label = $PanelContainer/VBoxContainer/Label7

@export var is_test: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible:
		label.text = "FPS:" + "%.2f" % (1.0/delta)
		var plant_count: int = 0
		var build_count: int = 0
		var _furn_count: int = 0
		var other: int = 0
		for object in object_atlas.get_children():
			if object is GenericPlant:
				plant_count += 1
			elif object is GenericWall or GenericRoof or GenericDoor:
				build_count += 1
			else:
				other += 1
		label_2.text = str("plants:", plant_count, " builds:", build_count, " other:", other)
		do_mouse_stuff()
		if !is_test:
			do_player_stuff()
			do_time_stuff()

func do_mouse_stuff() -> void: 
	if world_manager != null:
		var mouse: Vector2 = world_manager.get_global_mouse_position()
		var layer := world_manager.trh.get_topmost_layer_at_global_pos(mouse)
		if layer != null:
			var loc := world_manager.convert_to_chunks_at_world_pos(mouse)
			var square_data:SquareData = world_manager.trh.request_square_at(loc[0], loc[1])
			if square_data:
				label_3.text = str("layer:", layer.elevation, " loc:", loc, " type: ", square_data.type, " wettness: ", square_data.water_saturation, " fertility: ", square_data.fertility)
			label_4.text = str("objects:", world_manager.get_objects_at_world_pos(mouse))
	else: 
		if get_parent().get_parent().ready:
			world_manager = get_parent().get_parent().world_manager

func do_player_stuff() -> void:
	if player != null && world_manager != null:
		label_5.text = str("global_loc: ", player.global_position, " loc: ", world_manager.convert_to_chunks_at_world_pos(player.global_position))
		label_6.text = str("hunger: ", player.health_handler.current_hunger, " health: ", player.health_handler.current_health)
	else:
		if get_parent().get_parent().ready:
			player = get_parent().get_parent().player

func do_time_stuff() -> void: 
	if lighting != null: 
		label_7.text = "time: " + lighting.formatted_datetime()
	else: 
		if get_parent().get_parent().ready:
			player = get_parent().get_parent().lighting
