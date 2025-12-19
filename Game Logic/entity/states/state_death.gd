extends PlayerState
class_name StateDeath

signal respawn_values()

func enter(_prev_state: String, _data:Dictionary = {}) -> void:
	super.enter(_prev_state, _data)
	tick_hunger = false
	player.velocity_handler.purge_speed()
	player.velocity_handler.stop()
	machine.print_if_debug("Entered StateDeath")

func exit() -> void:
	super.exit()
	machine.print_if_debug("Entered StateDeath")
	pass

func _process(_delta: float) -> void:
	#animation here when have animations
	pass

func respawn() -> void:
	configure_facing(Vector2i.DOWN)
	respawn_values.emit()
	await get_tree().create_timer(.1).timeout	
	transition_please.emit(PlayerState.IDLE, self)

#ill need some way to play jump + fall animations in the event that 
#death happens while jumping/falling
func force_death() -> void: 
	transition_please.emit(PlayerState.DEATH, self)