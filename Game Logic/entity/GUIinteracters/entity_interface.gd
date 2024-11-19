extends Control
class_name EntityInterface

signal close_dialogue()

var current_entity: Entity

@onready var conversation_button: Button = $ConversationButton

func _ready() -> void:
	self.visible = false

## Sets up [param entity] into this interface
func setup_entity(entity: Entity) -> void:
	current_entity = entity
	
	#if the entity has conversation, tell the conservation controller
	#otherwise, display the options

func close() -> void:
	close_dialogue.emit(current_entity)
	current_entity = null


func _on_conversation_button_pressed() -> void:
	# do more complex conversation logic here
	close() # Replace with function body.
