extends Resource
class_name EntityData

#if player/NPC, their unique ID. if animal, UNPC, or enemy, the name of the required scene
@export var unique_id : String 
@export var name : String #display name

enum EntityType{PLAYER, NPC, UNPC, ENEMY, ANIMAL}
@export var entity_type: EntityType

@export var current_chunk: Vector2
@export var current_location: Vector2

@export var health: int
@export var hunger: int

@export var inventory: InventoryData #loot table if non-player/npc
