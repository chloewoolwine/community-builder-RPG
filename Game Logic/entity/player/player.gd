extends CharacterBody2D
class_name Player

enum PlayerStates{STATE_MENU, STATE_IDLE, STATE_ACTION, STATE_TOOL, STATE_WALK, STATE_SPELL, STATE_DASH, 
		STATE_KNOCKBACK}

signal toggle_menu()
signal toggle_options() #options menu is a special boy
signal action(facing: int)
#signal taken_damage

@export var player_data: PlayerData
@export var inventory_data: InventoryData
@export var speed: int = 100
@export var friction: float = 0.01
@export var acceleration: float = 0.101
@export var dash_length: float = .3
@export var dash_cooldown: float = 3

var can_dash : bool = true
var equiped_item: SlotData
var state : PlayerStates = PlayerStates.STATE_IDLE
#used to store state whenever the game is paused + restore action
var prevState : PlayerStates = PlayerStates.STATE_IDLE
var input: Vector2
#(-1, 0) = right, (1,0) = left, (0,-1) = back, (0,1) = forward
var facing: Vector2 = Vector2(0, 1)

# raycast for world interaction
@onready var ray_cast_2d : RayCast2D = $RayCast2D
#reference to sprite
@onready var hair :AnimatedSprite2D = $Hair
@onready var outfit :AnimatedSprite2D = $Outfit

@onready var health_handler:HealthHandler= $HealthHandler
@onready var velocity_handler:VelocityHandler = $VelocityHandler
@onready var animation_handler:AnimationHandler = $AnimationHandler

#THIS IS TEMPORARY. TODO: remove this when the animations create hitboxes properly
@onready var sword_hitbox:CollisionShape2D = $HitBox/CollisionShape2D
 
func _ready() -> void:
	toggle_menu.connect(toggle_menu_state)
	toggle_options.connect(toggle_menu_state)
	
	#TODO: link these up with the GUI through GAME
	health_handler.health_zero.connect(die)
	health_handler.health_increased.connect(heal)
	health_handler.health_decreased.connect(hurt)
	
	#set hair and outfit... eventually 
	#animation_player.add_animation_library()

func _physics_process(_delta: float) -> void: 
	match state:
		PlayerStates.STATE_IDLE:
			if !velocity_handler.in_knockback:
				velocity_handler.purge_speed()
			purge_input()
			get_input()
		PlayerStates.STATE_WALK:
			get_input()
			if input.length() > 0:
				velocity_handler.move_to(input)
			else:
				velocity_handler.stop()
		PlayerStates.STATE_DASH:
			velocity_handler.move_to_accel(facing, 3, acceleration)
		PlayerStates.STATE_ACTION:
			pass
		PlayerStates.STATE_TOOL:
			pass
	updateAnimation()
	
func purge_input() -> void:
	input.y = 0
	input.x = 0
	
func get_input() -> void:
	#TODO: *maybe* change this structure to a match instead of ifs
	#not sure how that would effect perfomrance
	if Input.is_action_pressed('down'):
		input.y = 1
		facing = Vector2(0, 1)
		ray_cast_2d.rotation_degrees = 0
		#TODO: removethese when the slash animations are fixed
		sword_hitbox.position.y = 127
		sword_hitbox.position.x = 0
		sword_hitbox.rotation_degrees = 0
		state = PlayerStates.STATE_WALK
	elif Input.is_action_pressed('up'):
		input.y = -1
		facing = Vector2(0, -1)
		ray_cast_2d.rotation_degrees = 180
		state = PlayerStates.STATE_WALK
		sword_hitbox.position.y = -127
		sword_hitbox.position.x = 0
		sword_hitbox.rotation_degrees = 0
	else:
		input.y = 0 
	if Input.is_action_pressed('right'):
		input.x = 1
		facing = Vector2(1, 0)
		ray_cast_2d.rotation_degrees = 270
		state = PlayerStates.STATE_WALK
		sword_hitbox.position.y = 0
		sword_hitbox.position.x = 127
		sword_hitbox.rotation_degrees = 90
	elif Input.is_action_pressed('left'):
		input.x = -1
		facing = Vector2(-1, 0)
		ray_cast_2d.rotation_degrees = 90
		state = PlayerStates.STATE_WALK
		sword_hitbox.position.y = 0
		sword_hitbox.position.x = -127
		sword_hitbox.rotation_degrees = 90
	else:
		input.x = 0 
	
	if input.x == 0 && input.y == 0:
		state = PlayerStates.STATE_IDLE
	
	#fix diagonals
	if Input.is_action_just_released('up'):
		input.y = 0
	if Input.is_action_just_released('right'):
		input.x = 0
	if Input.is_action_just_released('left'):
		input.x = 0
	if Input.is_action_just_released('down'):
		input.y = 0
	
func updateAnimation() -> void:
	animation_handler.flip_all_sprites(false)
	if facing.x == -1:
		animation_handler.flip_all_sprites(true)
	if facing.y == 1:
		move_child(hair, 1)
	else:
		move_child(hair, 2)
	match state:
		PlayerStates.STATE_IDLE, PlayerStates.STATE_MENU:
			animation_handler.travel_to_and_blend("Idle", facing)
		PlayerStates.STATE_WALK:
			animation_handler.travel_to_and_blend("Walk", facing)
		PlayerStates.STATE_ACTION:
			animation_handler.travel_to_and_blend("Slash", facing)
			#remove later
			hair.visible = false
			outfit.visible = false
		PlayerStates.STATE_DASH:
			#dash animation
			animation_handler.travel_to_and_blend("Idle", facing)
		PlayerStates.STATE_TOOL:
			pass #TODO: different animations for different actions

func _unhandled_input(_event: InputEvent)  -> void: 
	#Note: chests + dialogues are opened up with do_action and state is handled
	#there. they emit their OWN toggle menu events
	if Input.is_action_just_pressed("inventory_menu"):
		toggle_menu.emit()
	if Input.is_action_just_pressed("option_menu"):
		toggle_options.emit()
	
	if Input.is_action_just_pressed("action"):
		if state == PlayerStates.STATE_IDLE || state == PlayerStates.STATE_WALK:
			do_action()
	if Input.is_action_just_pressed("dash"): 
		if can_dash && (state == PlayerStates.STATE_IDLE || state == PlayerStates.STATE_WALK):
			state = PlayerStates.STATE_DASH
			time_dash()
			time_dash_cooldown()
			
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
	
func hurt(culprit:HitBox, _current_health:int) -> void:
	if culprit and "knockback" in culprit:
		@warning_ignore("narrowing_conversion")
		velocity_handler.knockback(culprit.global_position, culprit.knockback)
	
func heal(_current_health:int) -> void:
	print("some gui notice should go here too")

func toggle_menu_state() -> void:
	velocity = Vector2(0,0)
	input.y = 0
	input.x = 0
	if(state == PlayerStates.STATE_MENU):
		if prevState == PlayerStates.STATE_MENU:
			prevState = PlayerStates.STATE_IDLE
		state = prevState
	else:
		prevState = state
		state = PlayerStates.STATE_MENU
	
#cases:
#1 = nothing is there, player is holding no tool. nothing happens
#2 = object is there, not interactable. nothing happens
#3 = object is there, interactable, but player does not meet requirements. nothing happens. 
#(touching tree w/out axe)
#4 = object is there, interactable, has requirements that player meets. animation plays/menu opens
#5 = nothing is there, but the player has an item equiped. something happens with the item depending 
#on it 
#TODO: clean this up!!
func do_action() -> void:
	#if player is holding tool, or if player is in front of interactable
	var cast:Object = ray_cast_2d.get_collider()
	if cast && cast.has_method("player_interact"):
		print_if_debug("hit" + cast.get_name())
		if cast.has_method("interact_requirements"):
			pass
		else:
			cast.player_interact()
			toggle_menu_state()
	#if we are holding a usuable item...
	elif equiped_item && equiped_item.item_data:
		if equiped_item.item_data is ItemDataTool: #todo change this to Weapon
			match equiped_item.item_data.type:
				ItemDataTool.WeaponType.AXE:
					pass
				ItemDataTool.WeaponType.SWORD:
					state = PlayerStates.STATE_ACTION
					sword_hitbox.disabled = false
				ItemDataTool.WeaponType.HOE:
					pass
				ItemDataTool.WeaponType.PICKAXE:
					pass
				ItemDataTool.WeaponType.HAMMER:
					pass
		if equiped_item.item_data is ItemDataConsumable: 
			print_if_debug("munch munch munch munch")
			equiped_item.quantity -= 1
			if equiped_item.quantity < 1:
				inventory_data.delete_item(inventory_data.equiped)
				equiped_item = null
			inventory_data.inventory_updated.emit(inventory_data)
		
func equip_item(slot_data: SlotData) -> void:
	equiped_item = slot_data
	if slot_data:
		print_if_debug("item equiped" + equiped_item.item_data.name)

#(-1, 0) = right, (1,0) = left, (0,-1) = back, (0,1) = forward
#TODO; fix this method, it's wrong
#input subtract will subtract that vector from local pos before converting to global
func get_raycast_target(subtract:Vector2 = Vector2(0,0)) -> Vector2:
	var target_position:Vector2 = ray_cast_2d.target_position
	match facing:
		1:
			target_position =  target_position * Vector2(1, -1)
		2:
			target_position =  target_position.orthogonal() 
		3:
			target_position =  target_position.orthogonal() * Vector2(-1, -1)
		4:
			pass
	print_if_debug("raycast target local vector: %v", target_position)
	return to_global(target_position - subtract)

func _on_animation_tree_animation_finished(anim_name:String) -> void:
	if "slash" in anim_name:
		state = PlayerStates.STATE_IDLE
		hair.visible = true
		outfit.visible = true
		velocity_handler.purge_speed()
		sword_hitbox.disabled = true
	#when i *have* a dash animation, link this up instead 
	if "hoe" in anim_name:
		state = PlayerStates.STATE_IDLE
	
#remove later
@onready var debug:bool = self.get_parent().get_parent().debug	
@warning_ignore("untyped_declaration")
func print_if_debug(message:String, _vector = null) -> void:
	if debug:
		if _vector:
			print(message, _vector)
		else:
			print(message)

#partially taken from reddit
#https://www.reddit.com/r/godot/comments/tefk75/best_top_down_movement_in_godot_4/
