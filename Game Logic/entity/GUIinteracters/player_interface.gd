extends Control
class_name PlayerInterface

#TODO: will have it's own inventory slots (3, maybe?) for player armor stuff
#these slots will only accept armor. then it will apply those buffs through
#the player through a reference, and update it's own display

@onready var gear:Control = $Gear
@onready var craft:Control = $Craft
@onready var spells:Control = $Spells
@onready var tab_bar:TabBar = $TabBar

func set_player(_player: Player) -> void:
	#todo: set the player panel with stuff
	#also todo: design the player panel
	pass
