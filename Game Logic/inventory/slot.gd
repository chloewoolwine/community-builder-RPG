extends PanelContainer
class_name Slot

signal slot_clicked(index: int, button: int)

@onready var texture_rect:TextureRect = $MarginContainer/TextureRect
@onready var quantity_label:Label = $QuantityLabel

@onready var highlight: TextureRect = $MarginContainer/Highlight

func set_slot_data(slot_data: SlotData) -> void:
	var item_data:ItemData = slot_data.item_data
	texture_rect.texture = item_data.texture
	tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide() # just in case

func set_highlight(val: bool) -> void:
	highlight.visible = val

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and (event.button_index == MOUSE_BUTTON_LEFT \
		or event.button_index == MOUSE_BUTTON_RIGHT) \
		and event.is_pressed():
			print("slot clicked")
			slot_clicked.emit(get_index(), event.button_index)
