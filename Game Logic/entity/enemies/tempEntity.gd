extends Node2D
class_name Entity

signal toggle_menu(entity: Entity)
@onready var interaction_hitbox:InteractionHitbox = $InteractionHitbox

func _ready() -> void:
	interaction_hitbox.player_interacted.connect(emit_menu_toggle)
	
func emit_menu_toggle(_hitbox: InteractionHitbox) -> void:
	toggle_menu.emit(self)
