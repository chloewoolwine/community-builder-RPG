extends Area2D

#hurt boxes are on layers, hit boxes are on masks
#hurt boxes are where the entities "live"... masks just look for them :D 

signal health_increased(current_healh : int)
signal health_decreased(culprit, current_healh : int)
signal health_zero()

@export var max_health : int = 100
@export var current_health : int = 100

@export var has_iframes: bool = false
@export var iframe_secs: float = .3
var in_iframe: bool = false

#enemy layer does not NECCESARILY mean a combatant, just anything a player can hit
var enemy_layer : bool = false
var player_layer : bool = false
var npc_layer : bool = false

func _ready():
	enemy_layer = get_collision_layer_value(2)
	player_layer = get_collision_layer_value(4)
	npc_layer = get_collision_layer_value(5)

func change_health(amount: int, _culprit = null):
	if amount > 0:
		health_increased.emit(current_health)
	elif amount < 0:
		health_decreased.emit(_culprit, current_health)
	else: #amount == 0
		return
	current_health = current_health + amount
	if current_health > max_health:
		current_health = max_health
	if current_health < 0:
		current_health = 0
		health_zero.emit()
	
func increase_health(amount: int):
	change_health(amount)
	
func decrease_health(amount: int, culprit):
	change_health(amount * -1, culprit)

func _on_area_entered(area):
	#area should be damaging attack, only a *damaging action* should be able to find this
	#print(str("health component of ", self.get_parent().name, " hit"))
	if !in_iframe:
		decrease_health(area.touch_damage, area)
		print(str("damage = ", area.touch_damage, "  health = ", current_health))
		if has_iframes:
			time_iframe()
	
func time_iframe():
	in_iframe = true
	await get_tree().create_timer(iframe_secs).timeout
	in_iframe = false
	#print("iframe over")
