extends Node2D
class_name ToolComponent

signal tool_use_complete()
signal spawn_stuff_please(stuff: Array[ItemData])

@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox

@export var tool_type:ItemDataTool.WeaponType
@export var hits_required: int = 1
@export var loot_table_complete: LootTable
@export var each_hit_grants_roll: bool
@export var single_hit_loot: LootTable

var current_hits:int

func _ready() -> void:
	interaction_hitbox.tool_required = tool_type
	interaction_hitbox.type = InteractionHitbox.TYPE.TOOL
	interaction_hitbox.player_interacted.connect(player_interacted)

func player_interacted() -> void:
	#print("player interacted, curr hits: ", current_hits, " required: ", hits_required)
	current_hits += 1
	if current_hits >= hits_required:
		var pickups: Array[ItemData] 
		pickups.append_array(loot_table_complete.roll(RandomNumberGenerator.new(),1))
		spawn_stuff_please.emit(pickups)
		tool_use_complete.emit()
	elif each_hit_grants_roll:
		var pickups: Array[ItemData] 
		pickups.append_array(single_hit_loot.roll(RandomNumberGenerator.new(),1))
		spawn_stuff_please.emit(pickups)
