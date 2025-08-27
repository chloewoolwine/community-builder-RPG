extends Node
class_name Brush

var radius:int = 1
var position: Vector2i

var rand: FastNoiseLite
var random_factor: int = 1
var min_r:int = 0
var max_r:int = 9223372036854775807

func _init(rad: int, pos: Vector2i, random_fact: int = 1) -> void:
	radius = rad
	position = pos
	if rad > max_r:
		max_r = rad
	random_factor = random_fact 

func increase() -> void:
	radius += 1
	if radius > max_r:
		radius = max_r

func decrease() -> void: 
	radius -= 1
	if radius < min_r:
		radius = min_r

func rand_size_change() -> void: 
	if rand:
		var num := rand.get_noise_1d(random_factor)
		if num > 0:
			radius += 1
		else:
			radius -= 1
		if radius < min_r:
			radius = min_r
		if radius > max_r:
			radius = max_r
		random_factor += 1

func next(dir: Vector2i, change_size: bool = true) -> Array[Vector2i]: 
	position += dir
	if rand && change_size:
		rand_size_change()
	return get_pix()

func get_pix() -> Array[Vector2i]:
	var pix: Array[Vector2i]
	
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			pix.append(position + Vector2i(x,y))
	
	if radius == 0:
		pix.append(position)
	
	return pix
