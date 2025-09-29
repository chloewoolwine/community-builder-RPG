extends StaticBody2D
class_name GenericObject

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])
signal object_removed(me: ObjectData)

@export var object_id: String
@export var loot_table: LootTable
@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox
@onready var plant_component: PlantComponent= $PlantComponent
@onready var simple_collectable: SimpleCollectable = $SimpleCollectable
@onready var age_component: AgeingComponent = $AgeingComponent

var object_data: ObjectData
var square_data: SquareData

var debug: bool = false
