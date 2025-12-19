extends StaticBody2D
class_name GenericObject

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])
signal replace_me(object_id:String, with_tags: Dictionary)
signal object_removed(me: ObjectData)

@export var object_id: String
@export var loot_table: LootTable

@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox
@onready var plant_component: PlantComponent= $PlantComponent
#TODO: gotta figure out how to engineer this correctly
#PROBABLY: make different components for each collectable type (use tool, click) and have them added
#as individual components with seperate hitboxes :thumbsup"
#@onready var simple_collectable: SimpleCollectable = $SimpleCollectable
@onready var age_component: AgeingComponent = $AgeingComponent
#don't worry about this for now- no animations
#@onready var object_appearance: ObjectAppearance

var object_data: ObjectData
var square_data: SquareData

var debug: bool = false

func _ready() -> void:
	pass
