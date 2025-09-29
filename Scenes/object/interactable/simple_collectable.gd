extends Node
class_name SimpleCollectable

@export var hitbox: InteractionHitbox
@export var drops:LootTable
@export var hits_required:int

@export var callable: Callable
var curr_hits: int = 0

func _ready() -> void:
	hitbox.player_interacted.connect(on_hit)

func on_hit() -> void: 
	curr_hits += 1
	if hits_required <= curr_hits:
		drops
	pass
