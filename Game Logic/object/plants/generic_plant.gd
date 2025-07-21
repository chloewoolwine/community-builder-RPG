extends Area2D
class_name GenericPlant

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])
signal object_removed(me: ObjectData)

@export var object_id: String

@onready var plant_component : PlantComponent= $PlantComponent
@onready var interaction_hitbox : InteractionHitbox = $InteractionHitbox
@onready var plant_appearance : PlantAppearance
@export var loot_table: LootTable
@export var axe_hits: int ## These aren't saved- when trees are unloaded/reloaded this will reset. this is intended

var object_data: ObjectData
var square_data: SquareData
# TODO: pass the square_data into here upon instantiation

var is_tree: bool = false

var debug: bool = false

func _ready() -> void:
	#print("last loaded:", object_data.last_loaded_minute)
	for child in get_children():
		if child is PlantAppearance: 
			plant_appearance = child
			if child is TreeAppearance:
				is_tree = true
	# this is a little bit naughty! get_children() is blocking 
	if get_tree().current_scene == self:
		#we are debug, root
		debug = true
		get_tree().create_timer(1).timeout.connect(func()-> void: onChangeStage(1, false) )
		get_tree().create_timer(4).timeout.connect(func()-> void: onChangeStage(2, false) )
		object_data = ObjectData.new()
	# might become a problem later
	if object_data == null:
		push_error(object_id + " moved into game with null object data. Killing self.")
		self.queue_free()
		return
	#print("plant location: ", object_data.position, " ", object_data.chunk)
	plant_component.change_stage.connect(onChangeStage)
	interaction_hitbox.player_interacted.connect(checkForHarvest)
	if "age" in object_data.object_tags.keys():
		plant_component.set_age(object_data.object_tags["age"])
	else:
		plant_component.set_age(0)
	
func onChangeStage(new_stage: int, collision: bool) -> void: 
	plant_appearance.change_growth_stage(new_stage)
	print("collision: ", collision)
	#print("new_stage: ", new_stage)
	interaction_hitbox.set_to_wall(collision)
	
func checkForHarvest(_hitbox: InteractionHitbox) -> void:
	if plant_component.mature:
		harvest()

func harvest() -> void:
	if is_tree:
		axe_hits -= 1
		print("harvest axe hits: ", axe_hits)
		spawn_pickups.emit(self.global_position, loot_table.roll(RandomNumberGenerator.new(), 1, false))
		if axe_hits <= 0: 
			plant_appearance.playharvestanim()
			generate_pickups_and_signal()
			object_removed.emit(object_data)
			plant_component.set_age(-1)
	else:
		if plant_component.destroy_on_harvest:
			destroy() 
		else:
			plant_appearance.playharvestanim()
			generate_pickups_and_signal()
		
func generate_pickups_and_signal() -> void:
	if loot_table:
		var pickups: Array[ItemData] = loot_table.roll(RandomNumberGenerator.new())
		spawn_pickups.emit(self.global_position, pickups)

func destroy() -> void: 
	plant_appearance.playharvestanim()
	generate_pickups_and_signal()
	if plant_component.destroy_on_harvest:
		object_removed.emit(object_data)
		self.queue_free()
