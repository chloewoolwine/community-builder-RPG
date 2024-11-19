extends Node2D
class_name Chest

@warning_ignore("untyped_declaration")
signal toggle_menu(external_inventory_owner)

@export var inventory_data: InventoryData

@onready var interaction_hitbox:InteractionHitbox = $InteractionHitbox

func _ready() -> void:
	inventory_data.setOwner(self)
	interaction_hitbox.player_interacted.connect(open_chest)

func open_chest(_self: InteractionHitbox)-> void:
	toggle_menu.emit(self)
