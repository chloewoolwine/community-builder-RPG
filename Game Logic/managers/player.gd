extends CharacterBody2D
class_name Player
#partially taken from reddit
#https://www.reddit.com/r/godot/comments/tefk75/best_top_down_movement_in_godot_4/

signal toggle_menu()
signal action(facing: int)
#signal taken_damage

@export var inventory_data: InventoryData
var equiped_item: SlotData

@export var speed: int = 100
@export var friction: float = 0.01
@export var acceleration: float = 0.1

@onready var ray_cast_2d = $RayCast2D
@onready var animations = $AnimatedSprite2D

#hopefully this will be useful for combat :D
enum {STATE_MENU, STATE_IDLE, STATE_ACTION, STATE_TOOL, STATE_WALK, STATE_SPELL, STATE_HURT} 
var state = STATE_IDLE
#used to store state whenever the game is paused + restore action
var prevState = STATE_IDLE
var prevVelocity 
var input: Vector2
#1 = up, 2 = right, 3 = left, 4 = down todo: make a real enum
var facing = 4

func _ready():
	toggle_menu.connect(turn_state_to_menu)

func updateAnimation():
	animations.set_flip_h(false)
	if facing == 3:
		animations.set_flip_h(true)
	match state:
		STATE_IDLE:
			match facing:
				1:
					animations.play("idle_back")
				2:
					animations.play("idle_side")
				3:
					animations.play("idle_side")
				4:
					animations.play("idle_forward")
		STATE_WALK:
			match facing:
				1:
					animations.play("walk_back")
				2:
					animations.play("walk_side")
				3:
					animations.play("walk_side")
				4:
					animations.play("walk_forward")
		STATE_ACTION:
			pass
		STATE_TOOL:
			pass #TODO: different animations for different actions
			#if player not holding item, no animation
			

func _physics_process(_delta):
	match state:
		STATE_IDLE:
			get_input()
			if input.length() > 0:
				state = STATE_WALK
		STATE_WALK:
			get_input()
			if input.length() > 0:
				velocity = velocity.lerp(input.normalized() * speed, acceleration)
			else:
				velocity = velocity.lerp(Vector2.ZERO, friction)
				state = STATE_IDLE
			move_and_slide()
		STATE_ACTION:
			pass
		STATE_TOOL:
			pass
			#todo: do something here
			#if in front of interactable, interact w it (open menu,
			#if holding tool, play animation until completion, then revert back to idle state
	updateAnimation()
	
func get_input():
	#TODO: *maybe* change this structure to a match instead of ifs
	#not sure how that would effect perfomrance
	#match event.button_index:
	#		MOUSE_BUTTON_LEFT: 
	if Input.is_action_pressed('down'):
		input.y = 1
		facing = 4
		ray_cast_2d.rotation_degrees = 0
	if Input.is_action_pressed('up'):
		input.y = -1
		facing = 1
		ray_cast_2d.rotation_degrees = 180
	if Input.is_action_pressed('right'):
		input.x = 1
		facing = 2
		ray_cast_2d.rotation_degrees = 270
	if Input.is_action_pressed('left'):
		input.x = -1
		facing = 3
		ray_cast_2d.rotation_degrees = 90
	
	#fix diagonals
	if Input.is_action_just_released('up'):
		input.y = 0
	if Input.is_action_just_released('right'):
		input.x = 0
	if Input.is_action_just_released('left'):
		input.x = 0
	if Input.is_action_just_released('down'):
		input.y = 0
	

func _unhandled_input(_event: InputEvent) -> void: 
	#TODO: this is going to need to be changed when construction + dialogue happens
	#need to check what *kind* of menu we're in- a construction or dialogue menu
	#shouldn't be closed with an escape
	if Input.is_action_just_pressed("menu_toggle"):
		#if menu is closable by the player THEN toggle menu
		toggle_menu.emit()
	
	if Input.is_action_just_pressed("action"):
		do_action()
		
func turn_state_to_menu():
	if(state == STATE_MENU):
		state = prevState
		velocity = prevVelocity
	else:
		prevVelocity = velocity
		prevState = state
		state = STATE_MENU
	
#cases:
#1 = nothing is there, player is holding no tool. nothing happens
#2 = object is there, not interactable. nothing happens
#3 = object is there, interactable, but player does not meet requirements. nothing happens. (touching tree w/out axe)
#4 = object is there, interactable, has requirements that player meets. animation plays/menu opens
func do_action():
	#action.emit(facing) 
	#if player is holding tool, or if player is in front of interactable
	print_if_debug("player action clicked")
	var cast = ray_cast_2d.get_collider()
	if cast && cast.has_method("player_interact"):
		print_if_debug("hit" + cast.get_name())
		if cast.has_method("interact_requirements"):
			pass
		else:
			cast.player_interact()
			#todo: check if its a chest?
			turn_state_to_menu()
	#if we are holding a usuable item...
	elif equiped_item && equiped_item.item_data:
		if equiped_item.item_data is ItemDataTool: 
			print_if_debug("violence: taken")
		if equiped_item.item_data is ItemDataConsumable: 
			print_if_debug("munch munch munch munch")
			equiped_item.quantity -= 1
			if equiped_item.quantity < 1:
				inventory_data.delete_item(inventory_data.equiped)
				equiped_item = null
			inventory_data.inventory_updated.emit(inventory_data)
		
func equip_item(slot_data: SlotData):
	equiped_item = slot_data
	if slot_data:
		print_if_debug("item equiped" + equiped_item.item_data.name)

#1 = up, 2 = right, 3 = left, 4 = down todo: make a real enum
#input subtract will subtract that vector from local pos before converting to global
func get_raycast_target(subtract = Vector2(0,0)) -> Vector2:
	var target_position = ray_cast_2d.target_position
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

@onready var debug = self.get_parent().get_parent().debug	
func print_if_debug(message, _vector = null):
	if debug:
		if _vector:
			print(message, _vector)
		else:
			print(message)
