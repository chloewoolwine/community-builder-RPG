extends Node
class_name WorldSaver
@onready var world_generator: WorldGenerator = $WorldGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if world_generator == null:
		return
	if world_generator.world_to_save != null:
		save_world(world_generator.world_to_save, "")
	world_generator.save_world.connect(save_world)

func save_world(world: WorldData, _location: String) -> void: 
	print('saving da world...')
	var save_result:Error
	if _location.length() > 0:
		save_result = ResourceSaver.save(world, _location)
	else: 
		save_result = ResourceSaver.save(world, str('res://Test/data/world_datas/world', world.world_seed, '-saved.tres'))
	if save_result != OK:
		print(save_result)
