this folder contains everything that would be considered "game logic"

this includes scripts + resources, but NOT finished scene prefabs

inventory system is explained in inventory.gd and from https://www.youtube.com/watch?v=V79YabQZC1s
brief overview:
	inventories are made up of the "data" side and the "GUI" side. 
	"data": inventory_data.gd, slot_data.gd, item_data.gd 
	"gui": inventory.gd, inventory.tscn, slot.gd, slot.tscn
	
	inventory.gd recieves an inventory data instance (generally created at runtime, or loaded from a save)
	items are created as resources in item/items, see apple.tres
	
