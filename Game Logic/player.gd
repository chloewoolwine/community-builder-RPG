extends CharacterBody2D

#partially taken from reddit
#https://www.reddit.com/r/godot/comments/tefk75/best_top_down_movement_in_godot_4/

@export var inventory_data: InventoryData

@export var speed: int = 100
@export var friction: float = 0.01
@export var acceleration: float = 0.1
@onready var animations = $AnimatedSprite2D

#1 = up, 2 = right, 3 = left, 4 = down
var facing = 4

# todo: i am sure there is a better way to do this, and it might not work w the combat system i want
# i need to MAKE a combat system fr fr 

func getInput():
	var input = Vector2()
	if Input.is_action_pressed('up'):
		input.y -= 1
		facing = 1
	if Input.is_action_pressed('right'):
		input.x += 1
		facing = 2
	if Input.is_action_pressed('left'):
		input.x -= 1
		facing = 3
	if Input.is_action_pressed('down'):
		input.y += 1
		facing = 4
	return input

func updateAnimation():
	animations.set_flip_h(false)
	if (velocity.abs().x < .1 && velocity.abs().y < .1):
		match facing:
			1:
				animations.play("idle_back")
			2:
				animations.play("idle_side")
			3:
				animations.set_flip_h(true)
				animations.play("idle_side")
			4:
				animations.play("idle_forward")
	else:
		match facing:
			1:
				animations.play("walk_back")
			2:
				animations.play("walk_side")
			3:
				animations.set_flip_h(true)
				animations.play("walk_side")
			4:
				animations.play("walk_forward")
			
		

func _physics_process(_delta):
	var direction = getInput()
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	move_and_slide()
	updateAnimation()
