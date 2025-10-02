extends Sprite2D
class_name Indicator

signal move_me(me: Indicator, player_pos: Vector2, item: ItemData)
signal placement(desired_spot: Vector2, player_pos: Vector2, item: ItemData)
signal modify(despired_spot: Location, player_pos: Vector2, action: String)

# Indicator calls "move_me" when in play
# "move_me" is picked up my the WorldManager who retrieves tilemap info for it
# and then sets valid_place
var valid_place: bool = false
var current_spot:Location

func _ready() -> void:
	self.scale = Vector2.ONE/self.get_parent().global_transform.get_scale()

#get_parent is bad practice, but im not sure how else to do this w/out hackyness
func _process(_delta: float) -> void:
	if self.visible:
		move_me.emit(self, get_parent().global_position, get_parent().get_equiped_item().item_data)
	
	if valid_place:
		#animation
		pass 
	else:
		#no animation
		pass

func attempt_modify(_player_loc: Vector2, action: String) -> bool:
	if self.global_position.distance_to(_player_loc) > 400: 
		print("too far :C")
		return false
	if current_spot == null:
		return false
	print("modify attempted, action ", action)
	modify.emit(current_spot, _player_loc, action)
	return true

func signal_placement_if_valid(item: ItemData, _player_loc:Vector2) -> bool:
	if valid_place and self.global_position.distance_to(_player_loc) <= 400:
		placement.emit(self.global_position, _player_loc, item)
		return true
	return false

func set_vis_based_on_item(slot: SlotData)-> void:
	self.visible = false
	if slot && slot.item_data:
		if slot.item_data.placeable:
			self.visible = true
		if slot.item_data is ItemDataTool:
			set_vis_for_tool(slot.item_data)

func set_vis_for_tool(item_data: ItemDataTool) -> void:
	match item_data.type:
		ItemDataTool.WeaponType.SWORD:
			self.visible = false
		ItemDataTool.WeaponType.HOE:
			self.visible = true
		ItemDataTool.WeaponType.CAN:
			self.visible = true
		ItemDataTool.WeaponType.AXE:
			self.visible = false
		ItemDataTool.WeaponType.SHOVEL:
			self.visible = true
		ItemDataTool.WeaponType.HAMMER:
			self.visible = true
		ItemDataTool.WeaponType.ROD:
			self.visible = false
