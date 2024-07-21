extends Node2D
class_name VelocityHandler

#This node should be the child of a character body 2d in order to work correctly
#This node doesn't not *actually move* the character, it just updates it's velocity

@export var body : CharacterBody2D
@export var knockbackable : bool = true
#1 is the standard amount of knockback. more is a light creature, less is a heavy creature
@export var knockback_mod : int = 1
#these will override of The Body has it 
@export var speed: int = 100
@export var friction: float = 0.01
@export var acceleration: float = 0.101

var in_knockback : bool = false

func _ready()->void:
	if body == null:
		if get_parent() is CharacterBody2D:
			body = get_parent()
		else:
			print(str("Warning! Velocity handler found without character body in ", get_parent().name))
			self.queue_free()
			
	if "speed" in body:
		speed = body.speed
	if "friction" in body:
		friction = body.friction
	if "acceleration" in body:
		acceleration = body.acceleration
		
func _physics_process(_delta:float)->void:
	if in_knockback:
		body.move_and_slide()
		
func move_to(direction: Vector2)->void:
	body.velocity = body.velocity.lerp(direction.normalized() * speed, acceleration)
	body.move_and_slide()

func move_to_accel(direction:Vector2, mod:int, accel:float)->void:
	body.velocity = body.velocity.lerp(direction.normalized() * speed * mod, accel)
	body.move_and_slide()
	
func stop()->void:
	body.velocity = body.velocity.lerp(Vector2.ZERO, friction)
	body.move_and_slide()
	
func purge_speed()->void:
	body.velocity.x = 0
	body.velocity.y = 0

func knockback(damage_source_pos: Vector2, intensity:int)->void:
	if knockbackable:
		var direction:Vector2 = damage_source_pos.direction_to(body.global_position)
		var strength:int = knockback_mod * intensity
		move_to_accel(direction, 1, strength)
		
		#TODO: this should be handled by animations
		in_knockback = true
		await get_tree().create_timer(.15).timeout
		in_knockback = false
		stop()
		purge_speed()
