extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button: int)

@export var slot_datas: Array[SlotData]
var equiped: int

@warning_ignore("untyped_declaration")
var owner
#if the type == player, add the 4 toolsbars?
#use whenever instantiating with code. chests = null
@warning_ignore("untyped_declaration")
func setOwner(_owner) -> void:
	owner = _owner

#SHOULD ONLY BE an entities inventory... 
func use_slot_data(index: int) -> void:
	var slot_data:SlotData = slot_datas[index]
	#print("inventory_data.use_slot_data; slot=", index)
	
	owner.equip_item(slot_data)
	inventory_updated.emit(self)
	equiped = index

func delete_item(index: int) -> void:
	slot_datas[index] = null
	inventory_updated.emit(self)

func pick_up_slot(slot_data: SlotData) -> bool:
	for index in slot_datas.size():
		if slot_datas[index] && slot_datas[index].can_merge(slot_data): #if they're the same, merge
			if slot_datas[index].merge(slot_data): #if we did *not* have overflow, return true
				inventory_updated.emit(self)
				return true
			#if we had overflow, continue
	
	for index in slot_datas.size():
		if !slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			return true
	return false

func grab_slot_data(index: int) -> SlotData:
	var data:SlotData = slot_datas[index]
	
	#if it exists, return it
	if(data):
		slot_datas[index] = null
		inventory_updated.emit(self)
	return data
	
func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var data:SlotData = slot_datas[index]
	
	var return_slot_data: SlotData
	if data && data.can_merge(grabbed_slot_data):
		if !data.merge(grabbed_slot_data): #merge if able, check for overflow
			return_slot_data = grabbed_slot_data
	else: #no merge, just swap em
		slot_datas[index] = grabbed_slot_data
		return_slot_data = data
	inventory_updated.emit(self)
	return return_slot_data
	
	
func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var data:SlotData = slot_datas[index]
	
	if !data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	else:
		if(data.can_merge(grabbed_slot_data) && data.quantity < SlotData.MAX_STACK_SIZE):
			data.merge(grabbed_slot_data.create_single_slot_data())
		
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null
	
#tells interface the slot was clicked
func on_slot_clicked(index: int, button: int)-> void:
	inventory_interact.emit(self, index, button)
