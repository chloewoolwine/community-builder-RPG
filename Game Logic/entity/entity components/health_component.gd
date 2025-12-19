extends Area2D
class_name HealthHandler

#hurt boxes are on layers, hit boxes are on masks
#hurt boxes are where the entities "live"... masks just look for them :D 

signal health_increased(current_healh : int)
signal health_decreased(culprit:HitBox, current_healh : int)
signal health_zero()

@export var max_hunger: float = 100
@export var current_hunger: float = 100
@export var hunger_base_fall_rate: float = 1
@export var starving_hunger_fall: float = 1

@export var max_health : int = 100
@export var current_health : float = 100

@export var has_iframes: bool = false
@export var iframe_secs: float = .3

var in_iframe: bool = false
var starving: bool = false
var should_hunger_tick: bool = false
var player: Player

func reset_to_max(do_health: bool = true, do_hunger: bool = true) -> void:
	if do_health:
		current_health = max_health
	if do_hunger:
		current_hunger = max_hunger

func change_health(amount: float, _culprit:HitBox = null)->void:
	if current_health <= 0 and amount < 0:
		return
	current_health = current_health + amount
	if amount > 0:
		health_increased.emit(current_health)
	elif amount < 0:
		health_decreased.emit(_culprit, current_health)
	else: #amount == 0
		return
	if current_health > max_health:
		current_health = max_health
	if current_health <= 0:
		current_health = 0
		health_zero.emit()
	
func increase_health(amount: int)->void:
	change_health(amount)
	
func decrease_health(amount: int, culprit:HitBox)->void:
	change_health(amount * -1, culprit)

func _on_area_entered(area: HitBox)->void:
	#area should be damaging attack, only a *damaging action* should be able to find this
	#print(str("health component of ", self.get_parent().name, " hit"))
	if !in_iframe:
		decrease_health(area.touch_damage, area)
		print(str("damage = ", area.touch_damage, "  health = ", current_health))
		if has_iframes:
			time_iframe()
	
func time_iframe() -> void:
	in_iframe = true
	await get_tree().create_timer(iframe_secs).timeout
	in_iframe = false
	#print("iframe over")

func hunger_tick(_day:int, _hour:int, _minute:int) -> void:
	if should_hunger_tick:
		current_hunger = current_hunger - hunger_base_fall_rate
#		print("player hunger tick hunger: ", current_hunger)
		if current_hunger <= 0:
			current_hunger = 0
			@warning_ignore("narrowing_conversion")
			change_health(-starving_hunger_fall)
			starving = true
		else:
			starving = false
