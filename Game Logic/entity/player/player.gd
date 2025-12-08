extends CharacterBody2D
class_name Player

## TODO: organize and make normal

##TODO: need to make a load in state
enum PlayerStates{STATE_LOAD, STATE_MENU, STATE_IDLE, STATE_ACTION, STATE_TOOL, STATE_WALK, STATE_SPELL, STATE_JUMP, STATE_DASH, 
		STATE_KNOCKBACK, STATE_DEAD}

signal health_changed(new_health:int, total_health:int)
@warning_ignore("unused_signal")
signal toggle_menu()
@warning_ignore("unused_signal")
signal toggle_options() #options menu is a special boy
@warning_ignore("unused_signal")
signal action(facing: int)
#signal taken_damage

@export var player_data: PlayerData
@export var inventory_data: InventoryData
@export var speed: int = 170
@export var friction: float = 0.01
@export var acceleration: float = 0.101
@export var dash_length: float = .3
@export var dash_cooldown: float = 3

var can_dash : bool = true
var state : PlayerStates = PlayerStates.STATE_MENU
#used to store state whenever the game is paused + restore action
var prevState : PlayerStates = PlayerStates.STATE_IDLE
var input: Vector2
#(-1, 0) = right, (1,0) = left, (0,-1) = back, (0,1) = forward
var facing: Vector2 = Vector2(0, 1)

@onready var state_machine: GenericStateMachine = $StateMachine

# raycast for world interaction
@onready var ray_cast_2d : RayCast2D = $PlayerActionHandler/RayCast2D
#reference to sprite

@onready var health_handler:HealthHandler= $HealthHandler
@onready var velocity_handler:VelocityHandler = $VelocityHandler
@onready var animation_handler:AnimationHandler = $AnimationHandler
@onready var player_action_handler: PlayerActionHandler = $PlayerActionHandler
@onready var player_outfit_handler: PlayerOutfitHandler = $PlayerOutfitHandler
@onready var elevation_handler: ElevationHandler = $ElevationHandler

#THIS IS TEMPORARY. TODO: remove this when the animations create hitboxes properly
@onready var sword_hitbox:CollisionShape2D = $HitBox/CollisionShape2D
@onready var tile_indicator: Indicator = $TileIndicator

func _ready() -> void:
	#only leaves state load when told to by game.gd
	state = PlayerStates.STATE_LOAD
	
	#TODO: link these up with the GUI through GAME
	health_handler.health_zero.connect(die)
	health_handler.health_increased.connect(heal)
	health_handler.health_decreased.connect(hurt)
	
	player_action_handler.player_wants_to_eat.connect(attempt_eat)
	#set hair and outfit... eventually 
	#animation_player.add_animation_library()

func loading_done() -> void: 
	#print("loading done baby")
	state_machine.get_child(0).loading_done()
			
func time_dash() -> void:
	await get_tree().create_timer(dash_length).timeout
	state = PlayerStates.STATE_IDLE
	velocity_handler.purge_speed()
	
func time_dash_cooldown() -> void:
	can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
	
func die() -> void:
	print("if youre reading this... i am dead...")
	health_changed.emit(health_handler.current_health, health_handler.max_health)
	
func hurt(culprit:HitBox, _current_health:int) -> void:
	if culprit and "knockback" in culprit:
		@warning_ignore("narrowing_conversion")
		velocity_handler.knockback(culprit.global_position, culprit.knockback)
	health_changed.emit(health_handler.current_health, health_handler.max_health)
	
func heal(_current_health:int) -> void:
	health_changed.emit(health_handler.current_health, health_handler.max_health)

func attempt_eat(item:SlotData)->void:
	#TODO: check if the player is missing health/hunger first
	health_handler.change_health(item.item_data.heal_value)
	decrease_item_val(item)
			
func get_equiped_item() -> SlotData:
	return player_action_handler.equiped_item
		
func equip_item(slot_data: SlotData) -> void:
	player_action_handler.equiped_item = slot_data
	tile_indicator.set_vis_based_on_item(slot_data)

func decrease_item_val(item:SlotData)->void:
	item.quantity -= 1
	if item.quantity < 1:
		inventory_data.delete_item(inventory_data.equiped)
		item = null
		tile_indicator.visible = false
		player_action_handler.equiped_item = null
	inventory_data.inventory_updated.emit(inventory_data)
	
#(-1, 0) = right, (1,0) = left, (0,-1) = back, (0,1) = forward
#TODO; fix this method, it's wrong
#input subtract will subtract that vector from local pos before converting to global
func get_raycast_target() -> Vector2:
	var target_position:Vector2 = ray_cast_2d.target_position
	print_if_debug("raycast target local vector: %v", target_position)
	return to_global(target_position)
	
func teleport_to_square_data(data:SquareData, world_pos: Vector2) -> void:
	elevation_handler.current_elevation = data.elevation
	self.global_position = world_pos
	
func leave_options_menu() -> void:
	state_machine.find_child("Menu").leave_options_menu()

#remove later
@onready var debug:bool = false
@warning_ignore("untyped_declaration")
func print_if_debug(message:String, _vector = null) -> void:
	if debug:
		if _vector:
			print(message, _vector)
		else:
			print(message)

#partially taken from reddit
#https://www.reddit.com/r/godot/comments/tefk75/best_top_down_movement_in_godot_4/
