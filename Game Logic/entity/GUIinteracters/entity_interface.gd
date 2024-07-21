extends Control
class_name EntityInterface

signal close_dialogue()

#TODO: make some kind of "entity" class that all enemies/npcs can inherit from
@warning_ignore("untyped_declaration")
var current_entity

@onready var conversation_controller:ConversationController = $ConversationController

func _ready() -> void:
	self.visible = false
	conversation_controller.end_conversation.connect(close)
	
@warning_ignore("untyped_declaration")
func setup_entity(entity) -> void:
	current_entity = entity
	
	#if the entity has conversation, tell the conservation controller
	#otherwise, display the options

func close() -> void:
	close_dialogue.emit(current_entity)
	current_entity = null
