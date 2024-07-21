extends Control
class_name InventoryInterface

signal drop_slot_data_into_world(slot_data: SlotData)

var grabbed_slot_data: SlotData
@warning_ignore("untyped_declaration")
var external_inventory_owner

@onready var player_inventory: GenericInventoryDisplay = $PlayerInventory
@onready var grabbed_slot: Slot= $GrabbedSlot
@onready var external_inventory:GenericInventoryDisplay = $ExternalInventory
@onready var player_interface:PlayerInterface = $PlayerInterface #panel where player can Equip Stuff
@onready var data_tabs:Control = $DataTabs

func _ready() -> void:
	self.visible = false

func _physics_process(_delta:float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5,5)

#passes in the inventory used by the player, connects data to slots
func set_player_inventory_data(inventory_data: InventoryData, player: Player) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)
	player_interface.set_player(player)
	#todo: set player panel data 

@warning_ignore("untyped_declaration")
func set_external_inventory(new_external_inventory_owner) -> void:
	#print("set external inventory, inventory_interface.gd")
	external_inventory_owner = new_external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)
	
	#TODO: check if external inventory is a chest/npc/shop
	external_inventory.show()
	data_tabs.hide()

func clear_external_inventory() -> void:
	#print("set external inventory, inventory_interface.gd")
	if external_inventory_owner:
		var inventory_data:InventoryData = external_inventory_owner.inventory_data
		
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory_data(inventory_data)
		
		#TODO: check if external inventory is a chest/npc/shop
		external_inventory.hide()
		external_inventory_owner = null
	data_tabs.show()
	
#runs whenever the inventory data connected to this interface is interacted w
func on_inventory_interact(inventory_data: InventoryData, 
		index: int, button: int) -> void:
	
	match[grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]: #pick up 
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]: #drop
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]: #item use?
			pass
		[_, MOUSE_BUTTON_RIGHT]: #seperate stack
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
			
	update_grabbed_slot()
	
#the grabbed slot is anything the player is holding and trying to move around
func update_grabbed_slot() -> void:
	if (grabbed_slot_data):
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

#misc input event - dropping something into the world
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			&& event.is_pressed() \
			&& grabbed_slot_data:
		match event.button_index:
			#TODO: somehow make this work with a controller/??
			MOUSE_BUTTON_LEFT:
				drop_slot_data_into_world.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data_into_world.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
	update_grabbed_slot()

func _on_visibility_changed() -> void:
	if grabbed_slot_data:
		drop_slot_data_into_world.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
		
