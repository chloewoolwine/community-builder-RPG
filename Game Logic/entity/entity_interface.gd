extends Control

signal close_dialogue()

var current_entity

@onready var conversation_controller = $ConversationController

func _ready():
	self.visible = false
	conversation_controller.end_conversation.connect(close)
	
func setup_entity(entity):
	current_entity = entity
	
	#if the entity has conversation, tell the conservation controller
	#otherwise, display the options

func close():
	close_dialogue.emit(current_entity)
	current_entity = null
