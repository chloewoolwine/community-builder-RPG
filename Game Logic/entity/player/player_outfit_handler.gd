extends Node2D
class_name PlayerOutfitHandler

@export var velocity_handler: VelocityHandler
@export var animation_handler: AnimationHandler

var components: Array[AnimatedSprite2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if velocity_handler == null:
		push_warning("PlayerOutfitHandler in ", self.get_parent().name, " has no velocity handler assigned!")
		self.queue_free()
		
	for child in get_children(true):
		if child is AnimatedSprite2D:
			components.append(child)
			
	velocity_handler.jump_start.connect(func()->void:
		for comp in components:
			comp.modulate = Color(1, 0, 0, 1) # i really dont feel like making an animation right now 
	)
	velocity_handler.jump_apex.connect(func()->void:
		for comp in components:
			comp.modulate = Color(0, 0, 1, 1) 
	)
	velocity_handler.jump_complete.connect(func()->void:
		for comp in components:
			comp.modulate = Color(1, 1, 1, 1) 
	)
