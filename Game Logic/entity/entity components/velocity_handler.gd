extends Node2D
class_name VelocityHandler

#This node should be the child of a character body 2d in order to work correctly
#This node doesn't not *actually move* the character, it just updates it's velocity

signal try_step(curr_position: Vector2, curr_dir: Vector2, curr_elevation: int, callback: Callable)
signal step_complete(new_elevation: int, new_displayed_pos:Vector2)

@export var body : CharacterBody2D
@export var elevation_handler: ElevationHandler
## used if slopes + water effects this creature
@export var knockbackable : bool = true
#1 is the standard amount of knockback. more is a light creature, less is a heavy creature
@export var knockback_mod : int = 1
#these will override of The Body has it 
@export var speed: int = 100
@export var swimspeed: int = 90
@export var friction: float = 0.01
@export var acceleration: float = 0.101
@export var elevation_climb_speed: float = .9
@export var elevation_vert_change: float = .9
@export var elevation_pos_change_lr: int = 50

var curr_dirr: Vector2
var in_knockback : bool = false

var movement_tween: PropertyTweener

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
		
func do_physics(_delta:float)->void:
	if in_knockback:
		body.move_and_slide()
	if !movement_tween:
		for i in body.get_slide_collision_count():
			if body.get_slide_collision(i):
				var collider := body.get_slide_collision(i).get_collider()
				print("Collided with: ", collider.name)
				#print(collider.get_parent())
				if collider is TileMapLayer:
					if collider.name == "Base":
						try_step.emit(body.global_position, curr_dirr, elevation_handler.current_elevation, step_callback)
					elif collider.name == "WaterMapper":
						pass
					elif collider.name == "HigherElevationWarner":
						try_step.emit(body.global_position, curr_dirr, elevation_handler.current_elevation, step_callback)

func step_callback(up: bool, new_ele:int) -> void:
	#print("step callback: ", curr_dirr, " up:", up)
	var dirr:Vector2i = curr_dirr.normalized().snapped(Vector2.ONE)
	var direction:Vector2 = curr_dirr
	match dirr:
		Vector2i.UP:
			direction = direction + Vector2(0, -elevation_pos_change_lr)
		Vector2i.DOWN:
			direction = direction + Vector2(0, elevation_pos_change_lr)
		Vector2i.LEFT:
			if up:
				##going up
				direction = direction + Vector2(0,-elevation_vert_change)
			else:
				##going down
				direction = direction + Vector2(0,elevation_vert_change)
			direction = direction + Vector2(-elevation_pos_change_lr, 0)
		Vector2i.RIGHT:
			if up:
				##going up
				direction = direction + Vector2(0,-elevation_vert_change)
			else:
				##goign down
				direction = direction + Vector2(0,elevation_vert_change)
			direction = direction + Vector2(elevation_pos_change_lr, 0)
		_: # diagonals ....
			pass
	
	movement_tween = get_tree().create_tween().tween_property(body, "position", body.position + direction, elevation_climb_speed)
	await movement_tween.finished
	body.move_and_slide()
	step_complete.emit(new_ele, body.global_position)
	movement_tween = null
	#purge_speed()
		
func move_to(direction: Vector2)->void:
	#if elevationhandler and elevationhandler.onslope:
		#calculate_slope_movement(direction)
	#elif elevationhandler and elevationhandler.swimming:
		#body.velocity = body.velocity.lerp(direction.normalized() * swimspeed, acceleration)
		#body.move_and_slide()
	#else:
	body.velocity = body.velocity.lerp(direction.normalized() * speed, acceleration)
	body.move_and_slide()
	curr_dirr = direction

#this is: https://michaelbitzos.com/devblog/implementing-stairs-in-2d-top-down-games
#ur also kidna doing this if else statement every frame... consider fixing that
func calculate_slope_movement(direction: Vector2) -> void:
	var calc_speed: float = speed
	#if elevationhandler.slope_type == "hstair_r":
		#if direction.normalized().x > 0:
			##going up
			#direction = direction + Vector2(0,-elevation_vert_change)
			#pass
		#elif direction.normalized().x < 0:
			##goign down
			#direction = direction + Vector2(0,elevation_vert_change)
			#pass
	#elif elevationhandler.slope_type == "hstair_l":
		#if direction.normalized().x > 0:
			##going down
			#direction = direction + Vector2(0,elevation_vert_change)
			#pass
		#elif direction.normalized().x < 0:
			##going up
			#direction = direction + Vector2(0,-elevation_vert_change)
			#pass
				#
	#if abs(direction.y) > 0: 
		#calc_speed = calc_speed * elevation_climb_slowdown
		
	body.velocity = body.velocity.lerp(direction.normalized() * calc_speed, elevation_climb_speed)
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
