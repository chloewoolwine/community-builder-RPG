extends Node2D
class_name PlayerActionHandler

signal player_opened_menu(type:String)
signal player_using_tool(type:SlotData)
signal player_wants_to_eat(type:SlotData)
signal player_wants_to_plant(type:SlotData)

var equiped_item: SlotData

@onready var ray_cast_2d: RayCast2D = $RayCast2D

#cases:
#1 = nothing is there, player is holding no tool. nothing happens
#2 = object is there, not interactable. nothing happens
#3 = object is there, interactable, but player does not meet requirements. nothing happens. 
#(touching tree w/out axe)
#4 = object is there, interactable, has requirements that player meets. animation plays/menu opens
#5 = nothing is there, but the player has an item equiped. something happens with the item depending 
#on it 
#TODO: clean this up!! ITS SO BADss
func do_action() -> void:
	#if player is holding tool, or if player is in front of interactable
	var cast:Object = ray_cast_2d.get_collider()
	if cast && cast is InteractionHitbox && cast.accepting_interactions:
		if cast.needs_tool:
			if equiped_item && equiped_item.item_data:
				cast.player_interact(equiped_item.item_data)
		else: 
			cast.player_interact()
		if cast.is_chest:
			player_opened_menu.emit("chest")
		if cast.is_entity:
			player_opened_menu.emit("entity")
	#if we are holding a usuable item...
	elif equiped_item && equiped_item.item_data:
		if equiped_item.item_data is ItemDataTool:
			player_using_tool.emit(equiped_item)
		elif equiped_item.item_data is ItemDataConsumable: 
			player_wants_to_eat.emit(equiped_item)
		elif equiped_item.item_data is ItemDataSeed:
			player_wants_to_plant.emit(equiped_item)
