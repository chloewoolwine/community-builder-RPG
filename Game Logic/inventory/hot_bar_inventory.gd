extends PanelContainer

const Slot = preload("res://Scenes/UI/Inventory/slot.tscn")

signal hot_bar_use(index: int)

@onready var h_box_container = $MarginContainer/HBoxContainer

var highlight = -1

func _unhandled_key_input(event: InputEvent) -> void:
	if !visible or !event.is_pressed():
		return
	#TODO: make this work with the input map
	if range(KEY_1, KEY_6).has(event.keycode):
		var index = event.keycode - KEY_1
		set_highlight(index)
	#todo: this doesnt work either :c
	if Input.is_action_just_released('scrollup'):
		set_highlight(highlight + 1)
	if Input.is_action_just_released('scrolldown'):
		set_highlight(highlight - 1)

func set_highlight(index: int):
	if index < 0:
		index = 4
	if index > 4:
		index = 0
	highlight = index
	var children = h_box_container.get_children()
	for x in children.size():
		children[x].set_highlight(false)
		if x == highlight:
			children[x].set_highlight(true)
	hot_bar_use.emit(index)
	#print("highlight: %d" % highlight)
				

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hot_bar(inventory_data: InventoryData) -> void:
	#empty anything thats already in there
	for child in h_box_container.get_children():
			child.queue_free()
	#populate based on data 
	for x in 5: #TODO: change this based on how I want hotbar to function
		var slot_data = inventory_data.slot_datas[x]
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		if (slot_data != null):
			slot.set_slot_data(slot_data);
		if x == highlight:
			slot.set_highlight(true)
		else:
			slot.set_highlight(false)

