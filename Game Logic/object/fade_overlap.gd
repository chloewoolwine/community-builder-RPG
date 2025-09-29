extends Area2D
class_name FadeOverlap

## This object (if sprite) OR all children of this object (if not sprite) will fade slightly upon player overlap
@export var overlap_object:Node
@export_range(0, 1, .05) var transparent_opacity: float = .3
var all_sprites:Array[Sprite2D]

func _ready() -> void:
	if overlap_object == null:
		push_warning("overlap component not assigned in ", get_parent().name)
		self.queue_free()
		return
	if overlap_object is Sprite2D:
		all_sprites.append(overlap_object)
	else:
		for child in overlap_object.get_children():
			if child is Sprite2D:
				all_sprites.append(child)

#TODO: some tweening here to make it look nice when going transparent
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("going transparent")
		for sprite in all_sprites:
			sprite.self_modulate.a = transparent_opacity

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print("removing transparent")
		for sprite in all_sprites:
			sprite.self_modulate.a = 1
