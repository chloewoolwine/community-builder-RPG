extends Node2D
class_name PlayerActionHandler

signal player_wants_to_eat(type:SlotData)

var equiped_item: SlotData

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var player: Player = $".."
@onready var tile_indicator: Indicator = $"../TileIndicator"

#cases:
#1 = nothing is there, player is holding no tool. nothing happens
#2 = object is there, not interactable. nothing happens
#3 = object is there, interactable, but player does not meet requirements. nothing happens. 
#(touching tree w/out axe)
#4 = object is there, interactable, has requirements that player meets. animation plays/menu opens
#5 = nothing is there, but the player has an item equiped. something happens with the item depending 
#on it 
func do_action() -> String:
	#if player is holding tool, or if player is in front of interactable
	var cast:Object = ray_cast_2d.get_collider()
	if cast && cast is InteractionHitbox && cast.accepting_interactions:
		if cast.needs_tool and equiped_item and equiped_item.item_data is ItemDataTool and equiped_item.item_data.type == cast.tool_required:
			cast.player_interact()
		elif cast.is_chest:
			cast.player_interact()
			return "chest"
		elif cast.is_entity:
			cast.player_interact()
			return "entity"
		elif !cast.needs_tool:
			cast.player_interact()
	#if we are holding a usuable item...
	elif equiped_item && equiped_item.item_data:
		if equiped_item.item_data is ItemDataConsumable: 
			player_wants_to_eat.emit(equiped_item)
		elif equiped_item.item_data.placeable:
			if tile_indicator.signal_placement_if_valid(equiped_item.item_data, self.global_position): 
				player.decrease_item_val(equiped_item)
		elif equiped_item.item_data is ItemDataTool: 
			use_tool(equiped_item)
	return ""

func use_tool(item:SlotData)->void:
	match item.item_data.type:
		ItemDataTool.WeaponType.SWORD:
			player.state = player.PlayerStates.STATE_ACTION
			player.sword_hitbox.disabled = false
		ItemDataTool.WeaponType.HOE:
			tile_indicator.attempt_modify(player.global_position, "till")
		ItemDataTool.WeaponType.AXE:
			pass # idk what this would look like to be real 
		ItemDataTool.WeaponType.SHOVEL:
			tile_indicator.attempt_modify(player.global_position, "shovel")
		ItemDataTool.WeaponType.HAMMER:
			print("tool not yet implemented")
		ItemDataTool.WeaponType.ROD:
			print("tool not yet implemented")
		ItemDataTool.WeaponType.CAN:
			tile_indicator.attempt_modify(player.global_position, "water")
