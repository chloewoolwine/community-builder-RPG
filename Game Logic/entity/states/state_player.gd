extends State
class_name PlayerState

const IDLE = "Idle"
const WALK = "Walk"
const JUMP = "Jump"
const FALL = "Fall"
const DYING = "Die"
const LOAD = "Load"
const MENU = "Menu"
const FORCEJUMP = "ForceJump"
const FORCEFALL = "ForceFall"

#other possible states: knockback, death, attack, action (interact), swim, jumping into/out of water?, plus transitions?

var player: Player
var tick_hunger:bool = true
	
func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "PlayerState: Owner is not a Player!")

#TODO: I NEED TO TEST THIS SYSTEM ITS SO COMPLEX AND FRAGILE
func get_curr_input() -> Vector2i:
	var input:Vector2i = Vector2i.ZERO
	if Input.is_action_pressed('down'):
		input.y = 1
	if Input.is_action_pressed('up'):
		input.y = -1
	if Input.is_action_pressed('right'):
		input.x = 1
	if Input.is_action_pressed('left'):
		input.x = -1

	if not Input.is_action_pressed('down') and not Input.is_action_pressed('up'):
		input.y = 0
	if not Input.is_action_pressed('right') and not Input.is_action_pressed('left'):
		input.x = 0
	return input
	#print("curr input: ", input)

func configure_facing(input: Vector2i) -> void:
	if input.x != 0 && input.y != 0:
		#diagonal movement, prefer x axis for facing
		player.facing.x = input.x
		player.facing.y = 0
	else:
		if input.x == 0 && input.y == 0:
			#no movement, don't change facing
			return
		player.facing = input
