# GdUnit generated TestSuite
class_name ElevationMaskTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://Game Logic/world/mask.gd'
const MASK = preload("uid://cphd7kfw38oua")

#this probably didn't need all this testing, this mainly exists so i could learn some gdUnit
func test_change_elevation_to(fizz := Fuzzers.rangei(1, 10)) -> void:
	var mask:ElevationMask = MASK.instantiate()
	mask.elevation = 1
	add_child(mask)
	var rand := fizz.next_value()
	mask.change_elevation_to(rand)
	assert_int(mask.elevation).is_equal(rand)
	assert_int(mask.masks.size()).is_equal(rand+1)
	rand = fizz.next_value()
	mask.change_elevation_to(rand)
	assert_int(mask.elevation).is_equal(rand)
	assert_int(mask.masks.size()).is_equal(rand+1)
	mask.free()
