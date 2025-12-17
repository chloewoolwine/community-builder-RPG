extends Area2D
class_name HitBox

@export var touch_damage: int = 15:
	get:
		return touch_damage
	set(value):
		touch_damage = value

@export var knockback: float = 1:
	get:
		return knockback
	set(value):
		knockback = value

#unused- just for ideas
@export var armor_peen: float = 0:
	get:
		return armor_peen
	set(value):
		armor_peen = value
		
@export var effect: String:
	get:
		return effect
	set(value):
		effect = value
		
@onready var down: CollisionShape2D = $Down
@onready var up: CollisionShape2D = $Up
@onready var left: CollisionShape2D = $Left
@onready var right: CollisionShape2D = $Right

func set_facing(facing: Vector2i) -> void: 
	right.disabled = true
	left.disabled = true
	up.disabled = true
	down.disabled = true

	if facing.x > 0:
		right.disabled = false
	elif facing.x < 0:
		left.disabled = false
	elif facing.y > 0:
		down.disabled = false
	elif facing.y < 0:
		up.disabled = false

func disable_all() -> void:
	right.disabled = true
	left.disabled = true
	up.disabled = true
	down.disabled = true
