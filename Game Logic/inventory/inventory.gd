extends PanelContainer

#structure of all of this:
# Resources                       Scenes
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
	populate_item_grid(inventory_data.slot_datas)

# creates item grid based on # of inventory slots
# this same inventory can be used as a player's inventory
# or a chest C: 
func populate_item_grid(slot_datas: Array[SlotData]) -> void:
	#empty anything thats already in there
	for child in item_grid.get_children():
		child.queue_free()
		
	#populate based on data 
	for slot_data in slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		if (slot_data != null):
			slot.set_slot_data(slot_data);
