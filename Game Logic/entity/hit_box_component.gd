extends Area2D

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
