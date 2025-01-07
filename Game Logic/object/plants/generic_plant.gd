extends Area2D
class_name GenericPlant

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])
signal killing_myself(me: GenericPlant)

@export var object_id: String

@onready var plant_component : PlantComponent= $PlantComponent
@onready var interaction_hitbox : InteractionHitbox = $InteractionHitbox
@onready var plant_appearance : PlantAppearance
@export var loot_table: LootTable
@export var axe_hits: int ## These aren't saved- when trees are unloaded/reloaded this will reset. this is intended

var object_data: ObjectData
# WHEN i do water/fertility mechanics, just pass the square_data into here
# upon instantiation- the plant will take care of the rest

var is_tree: bool = false

func _ready() -> void:
	for child in get_children():
		if child is PlantAppearance: 
			plant_appearance = child
			if child is TreeAppearance:
				is_tree = true
	# this is a little bit naughty! get_children() is blocking 
	# might become a problem later
	if object_data == null:
		push_error(object_id + " moved into game with null object data. Killing self.")
		self.queue_free()
		return
	plant_component.change_stage.connect(onChangeStage)
	interaction_hitbox.player_interacted.connect(checkForHarvest)
	plant_component.set_age(object_data.object_tags["age"])
	
func onChangeStage(new_stage: int, collision: bool) -> void: 
	plant_appearance.change_growth_stage(new_stage)
	#print("collision: ", collision)
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
			killing_myself.emit(self)
			plant_component.set_age(-1)
	else: 
		plant_appearance.playharvestanim()
		generate_pickups_and_signal()
		if plant_component.destroy_on_harvest:
			killing_myself.emit(self)
			self.queue_free()
		
func generate_pickups_and_signal() -> void:
	if loot_table:
		var pickups: Array[ItemData] = loot_table.roll(RandomNumberGenerator.new())
		spawn_pickups.emit(self.global_position, pickups)
