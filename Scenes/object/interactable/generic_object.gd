extends Node2D
class_name GenericObject

signal spawn_pickups(spawnpoint: Vector2, datas: Array[ItemData])
signal replace_me(pos:Location, my_data: ObjectData, object_id:String, with_tags: Dictionary, failure_callback: Callable)
signal object_removed(me: ObjectData)
signal propogate(location: Location, object_id: String, tags: Dictionary)

@export var object_id: String

#@onready var interaction_hitbox: InteractionHitbox = $InteractionHitbox
var plant_component: PlantComponentV2
#TODO: gotta figure out how to engineer this correctly
#PROBABLY: make different components for each collectable type (use tool, click) and have them added
#as individual components with seperate hitboxes :thumbsup"
#@onready var simple_collectable: SimpleCollectable = $SimpleCollectable
var age_component: AgeingComponent
var tool_component: ToolComponent
#don't worry about this for now- no animations
#@onready var object_appearance: ObjectAppearance

var object_data: ObjectData
var square_data: SquareData

var debug: bool = false

func _ready() -> void:
	var children := get_children()
	for child in children:
		if child is PlantComponentV2:
			plant_component = child #only expect one
		elif child is AgeingComponent:
			age_component = child
		elif child is ToolComponent:
			tool_component = child
	
	if tool_component:
		setup_tool_component()
	if plant_component:
		setup_plant_component()
	if age_component:
		setup_age_component()

func setup_age_component() -> void: 
	age_component.update_age_in_data.connect(func(age: int) -> void:
		if object_data:
			object_data.object_tags["age"] = age
		if plant_component:
			plant_component.try_propogate()
	)
	age_component.max_age_reached.connect(func(_max_age: int) -> void:
		#print("max age reached by ", object_id, " at ", Location.new(object_data.position, object_data.chunk))
		if plant_component && !plant_component.next_stage_name.is_empty():
			#print("replacement underway")
			replace_me.emit(Location.new(object_data.position, object_data.chunk), object_data, plant_component.next_stage_name, object_data.object_tags, on_failed_replacement.bind("regress"))
	)
	#age_component.current_age = object_data.object_tags.get_or_add("age", 0)
	#age_component.owner_ready = true
	
	if plant_component:
		if plant_component.current_stage_num >= 0:
			age_component.max_age_minutes = plant_component.plant_gen_data.stage_minutes[plant_component.current_stage_num]

func setup_plant_component() -> void:
	plant_component.change_age_rate.connect(func(newrate: float) -> void: 
		if age_component:
			age_component.age_multiplier = newrate
	)
	plant_component.propogate_me.connect(func(location: Location, new_id: String, tags: Dictionary) -> void:
		var myloc := Location.new(object_data.position, object_data.chunk)
		propogate.emit(myloc.add_location(location), new_id, tags)
	)
	
func setup_tool_component() -> void: 
	tool_component.spawn_stuff_please.connect(func(stuff: Array[ItemData]) -> void:
		spawn_pickups.emit(self.global_position, stuff))
	tool_component.tool_use_complete.connect(func() -> void: 
		if plant_component && !plant_component.death_stage_name.is_empty():
			#print("replacement underway")
			replace_me.emit(Location.new(object_data.position, object_data.chunk), object_data, plant_component.death_stage_name, object_data.object_tags, on_failed_replacement.bind("delete"))
		else:
			object_removed.emit()
			self.queue_free())

func square_modified(square_data_new: SquareData) -> void:
	square_data = square_data_new
	if plant_component:
		plant_component.tile_changed(square_data_new)

func on_failed_replacement(type: String) -> void: 
	print("replacement failed for: ", object_id, " doing: ", type)
	if type == "delete":
		object_removed.emit()
		self.queue_free()
	if type == "regress":
		age_component.current_age = age_component.current_age - Constants.DAYS_TO_MINUTES #try once/day
