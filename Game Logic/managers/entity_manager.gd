extends Node
class_name EntityManager
@onready var player: Player = $Player

#note: saverloader does not see these entities. it recieves entityData from WorldData
@export var active_entities: Array[EntityData]


## TODO: dynamically link these up when an entity spawns:
## 			-elevation handler
