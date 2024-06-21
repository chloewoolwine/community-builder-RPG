extends PanelContainer

const Slot = preload("res://Scenes/UI/Inventory/slot.tscn")

signal hot_bar_use(index: int)

@onready var h_box_container = $MarginContainer/HBoxContainer

var highlight = -1

func _unhandled_key_input(event: InputEvent) -> void:
	if !visible or !event.is_pressed():
		return
	if range(KEY_1, KEY_7).has(event.keycode):
		var index = event.keycode - KEY_1
		highlight = index
		var children = h_box_container.get_children()
		for x in children.size():
			children[x].set_highlight(false)
			if x == highlight:
				children[x].set_highlight(true)
		hot_bar_use.emit(index)
				

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hot_bar(inventory_data: InventoryData) -> void:
	#empty anything thats already in there
	for child in h_box_container.get_children():
			child.queue_free()
	#populate based on data 
	for x in 6: #TODO: change this based on how I want hotbar to function
		var slot_data = inventory_data.slot_datas[x]
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		if (slot_data != null):
			slot.set_slot_data(slot_data);
		if x == highlight:
			slot.set_highlight(true)
		else:
			slot.set_highlight(false)

