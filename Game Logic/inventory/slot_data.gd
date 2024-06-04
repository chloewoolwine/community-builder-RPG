extends Resource
class_name SlotData

#this is a container to hold item datas, instantiated by     
#this object's parent (an inventory.gd)

const MAX_STACK_SIZE: int = 99

@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func set_quantity(value: int) -> void:
	quantity = value
	if(quantity > 1 && !item_data.stackable):
		quantity = 1
		push_error("%s is not stackable, quantity set to 1" + item_data.name)

#todo: how to do the hotbar? should i use this, or something else...
