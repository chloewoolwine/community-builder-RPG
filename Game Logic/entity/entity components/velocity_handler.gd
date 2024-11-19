extends Node2D
class_name VelocityHandler

#This node should be the child of a character body 2d in order to work correctly
#This node doesn't not *actually move* the character, it just updates it's velocity

@export var body : CharacterBody2D
## used if slopes + water effects this creature
@export var elevationhandler: ElevationHandler
@export var knockbackable : bool = true
#1 is the standard amount of knockback. more is a light creature, less is a heavy creature
@export var knockback_mod : int = 1
#these will override of The Body has it 
@export var speed: int = 100
@export var swimspeed: int = 90
@export var friction: float = 0.01
@export var acceleration: float = 0.101
@export var elevation_climb_slowdown: float = .9
@export var elevation_vert_change: float = .9

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
	if "swimspeed" in body:
		swimspeed = body.swimspeed
		
func _physics_process(_delta:float)->void:
	if in_knockback:
		body.move_and_slide()
		
func move_to(direction: Vector2)->void:
	if elevationhandler and elevationhandler.onslope:
		calculate_slope_movement(direction)
	elif elevationhandler and elevationhandler.swimming:
		body.velocity = body.velocity.lerp(direction.normalized() * swimspeed, acceleration)
		body.move_and_slide()
	else:
		body.velocity = body.velocity.lerp(direction.normalized() * speed, acceleration)
		body.move_and_slide()

#this is: https://michaelbitzos.com/devblog/implementing-stairs-in-2d-top-down-games
#ur also kidna doing this if else statement every frame... consider fixing that
func calculate_slope_movement(direction: Vector2) -> void:
	var calc_speed: float = speed
	if elevationhandler.slope_type == "hstair_r":
		if direction.normalized().x > 0:
			#going up
			direction = direction + Vector2(0,-elevation_vert_change)
			pass
		elif direction.normalized().x < 0:
			#goign down
			direction = direction + Vector2(0,elevation_vert_change)
			pass
	elif elevationhandler.slope_type == "hstair_l":
		if direction.normalized().x > 0:
			#going down
			direction = direction + Vector2(0,elevation_vert_change)
			pass
		elif direction.normalized().x < 0:
			#going up
			direction = direction + Vector2(0,-elevation_vert_change)
			pass
				
	if abs(direction.y) > 0: 
		calc_speed = calc_speed * elevation_climb_slowdown
		
	body.velocity = body.velocity.lerp(direction.normalized() * calc_speed, acceleration)
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
