extends Node2D
class_name WorldSaver
@onready var world_generator: WorldGenerator = $WorldGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if world_generator.world_to_save != null:
		save_world(world_generator.world_to_save, world_generator.path)
	world_generator.save_world.connect(save_world)

func save_world(world: WorldData, location: String) -> void: 
	print('saving da world...')
	var save_result:Error = ResourceSaver.save(world, location)

	#var save_result:Error = ResourceSaver.save(world, str('res://Test/data/world_datas/world', world.world_seed, '.tres'))
	if save_result != OK:
		print(save_result)
