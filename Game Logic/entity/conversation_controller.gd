extends PanelContainer

signal end_conversation()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		end_conversation.emit()
