extends Area2D
class_name Crop

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])

@export var object_id: String

@onready var plant_appearance : PlantApperance= $PlantAppearance
@onready var plant_component : PlantComponent= $PlantComponent
@onready var interaction_hitbox : InteractionHitbox = $InteractionHitbox

func _ready() -> void:
	plant_component.change_stage.connect(plant_appearance.change_growth_stage)
	interaction_hitbox.player_interacted.connect(checkForHarvest)
	
func checkForHarvest(_hitbox: InteractionHitbox) -> void:
	if plant_component.mature:
		harvest()

func harvest() -> void:
	plant_appearance.playharvestanim()
	generate_pickups_and_signal()
	if plant_component.destroy_on_harvest:
		self.queue_free()
		
func generate_pickups_and_signal() -> void:
	if plant_component.loot_table:
		var pickups: Array[ItemData] = plant_component.loot_table.roll(RandomNumberGenerator.new())
		spawn_pickups.emit(self.global_position, pickups)
