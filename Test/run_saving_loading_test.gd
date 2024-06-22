extends Node

@onready var saver_loader = $SaverLoader

func _ready():
	saver_loader.save()
	#saver_loader.load("Boy2024-06-21")
