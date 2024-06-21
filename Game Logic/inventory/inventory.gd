extends PanelContainer

#structure of all of this:
# Resources                       Scenes

#		---- Inventory_interface -------
#		|								|
#		V								V
# inventory_data.gd      <--->     inventory.gd
# 		|								|
#		V								V
# slot_data.gd                      slot.gd
# 		|								|
#		V								V
# item_data.gd						display

#this script *loads* an inventory_data and displays it using slot.tscn

const Slot = preload("res://Scenes/UI/Inventory/slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func clear_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.disconnect(populate_item_grid)
	
# creates item grid based on # of inventory slots
# this same inventory can be used as a player's inventory
# or a chest C: 
func populate_item_grid(inventory_data: InventoryData) -> void:
	#empty anything thats already in there
	for child in item_grid.get_children():
		child.queue_free()
		
	#populate based on data 
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if (slot_data != null):
			slot.set_slot_data(slot_data);
