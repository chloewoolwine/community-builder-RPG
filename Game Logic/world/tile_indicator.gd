extends Sprite2D
class_name Indicator

signal move_me(me: Indicator, player_spot: Vector2, item: ItemData)
signal placement(desired_spot: Vector2, elevation:ElevationLayer, item: ItemData)

@onready var elevation_handler: ElevationHandler = $"../ElevationHandler"

var valid_place: bool = false

func _ready() -> void:
	self.scale = Vector2.ONE/self.get_parent().global_transform.get_scale()

#get_parent is bad practice, but im not sure how else to do this w/out hackyness
func _process(_delta: float) -> void:
	if self.visible:
		move_me.emit(self, get_parent().global_position, get_parent().get_equiped_item().item_data)
	if valid_place:
		pass 
	else:
		pass

func signal_placement_if_valid(item: ItemData, _player_loc:Vector2) -> bool:
	if valid_place:
		placement.emit(self.global_position, elevation_handler.current_map_layer, item)
		return true
	return false

func set_vis_based_on_item(slot: SlotData)-> void:
	self.visible = false
	if slot && slot.item_data:
		if slot.item_data.placeable:
			self.visible = true
		if slot.item_data == ItemDataTool:
			set_vis_for_tool(slot.item_data)

func set_vis_for_tool(item_data: ItemDataTool) -> void:
	match item_data.type:
		ItemDataTool.WeaponType.SWORD:
			pass #no indicator
		ItemDataTool.WeaponType.HOE:
			self.visible = true
		ItemDataTool.WeaponType.AXE:
			self.visible = true
		ItemDataTool.WeaponType.PICKAXE:
			self.visible = true
		ItemDataTool.WeaponType.HAMMER:
			self.visible = true
		ItemDataTool.WeaponType.ROD:
			self.visible = true

func get_elevation() -> int:
	return elevation_handler.current_elevation
