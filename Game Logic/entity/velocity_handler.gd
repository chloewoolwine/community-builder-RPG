extends Node2D

#This node should be the child of a character body 2d in order to work correctly
#This node doesn't not *actually move* the character, it just updates it's velocity

@export var body : CharacterBody2D
@export var knockbackable : bool = true
#1 is the standard amount of knockback. more is a light creature, less is a heavy creature
@export var knockback_mod : int = 1

@export var speed: int = 100
@export var friction: float = 0.01
@export var acceleration: float = 0.101

func _ready():
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
			
func stop():
	body.velocity = body.velocity.lerp(Vector2.ZERO, friction)

func purge_speed():
	body.velocity.x = 0
	body.velocity.y = 0

func knockback(damage_source_pos: Vector2, intensity:int):
	if knockbackable:
		var direction = damage_source_pos.direction_to(body.global_position)
		var strength = knockback_mod * intensity
