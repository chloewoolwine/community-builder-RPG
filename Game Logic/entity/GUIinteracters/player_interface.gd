extends Control

#TODO: will have it's own inventory slots (3, maybe?) for player armor stuff
#these slots will only accept armor. then it will apply those buffs through
#the player through a reference, and update it's own display

@onready var gear = $Gear
@onready var craft = $Craft
@onready var spells = $Spells
@onready var tab_bar = $TabBar

func set_player(player: Player):
	#todo: set the player panel with stuff
	#also todo: design the player panel
	pass
