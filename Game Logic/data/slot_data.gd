extends Resource
class_name SlotData

#this is a container to hold item datas, instantiated by     
#this object's parent (an inventory.gd)

const MAX_STACK_SIZE: int = 99

@export var item_data: ItemData
@export_range(1, MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

func can_merge(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data && item_data.stackable && quantity < MAX_STACK_SIZE

#true if merged without overflow. false if overflowed
func merge(other_slot_data: SlotData) -> bool:
	quantity += other_slot_data.quantity
	if(quantity > MAX_STACK_SIZE):
		other_slot_data.quantity = quantity - MAX_STACK_SIZE
		quantity = MAX_STACK_SIZE
		return false
	return true
	
func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1 
	return new_slot_data

func set_quantity(value: int) -> void:
	quantity = value
	if(quantity > 1 && !item_data.stackable):
		quantity = 1
		push_error("%s is not stackable, quantity set to 1" + item_data.name)

#todo: how to do the hotbar? should i use this, or something else...
