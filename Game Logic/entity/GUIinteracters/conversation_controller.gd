extends PanelContainer
class_name ConversationController

signal end_conversation()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		end_conversation.emit()
