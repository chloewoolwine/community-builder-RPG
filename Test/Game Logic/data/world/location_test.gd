# GdUnit generated TestSuite
class_name LocationTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://Game Logic/data/world/location.gd'

func test_add_location() -> void:
	var fizz := Fuzzers.rangei(1, 31)
	var buzz := Fuzzers.rangei(32, 63)
	var location := Location.new(Vector2i(0, 0), Vector2i(0, 0))
	var add := Location.new(Vector2i(fizz.next_value(), fizz.next_value()), Vector2i(fizz.next_value(), fizz.next_value()))
	var result := location.add_location(add)
	var expected_chunk := location.chunk + add.chunk
	var expected_pos := location.position + add.position

	assert_vector(result.position).is_equal(expected_pos)
	assert_vector(result.chunk).is_equal(expected_chunk)
	
	var location1 := Location.new(Vector2i(0, 0), Vector2i(0, 0))
	add = Location.new(Vector2i(fizz.next_value() *-1, fizz.next_value()*-1), Vector2i(fizz.next_value()*-1, fizz.next_value()*-1))
	result = location1.add_location(add)
	expected_chunk = location1.chunk + add.chunk
	expected_pos = location1.position + add.position + Vector2i(32,32)

	assert_vector(result.position).is_equal(expected_pos)
	assert_vector(result.chunk).is_equal(expected_chunk)

	var location2 := Location.new(Vector2i.ZERO, Vector2i.ZERO)
	add = Location.new(Vector2i(buzz.next_value(), buzz.next_value()), Vector2i(buzz.next_value(), buzz.next_value()))
	result = location2.add_location(add)
	@warning_ignore("integer_division")
	expected_chunk = location2.chunk + add.chunk + Vector2i.ONE
	expected_pos = location2.position + add.position - Vector2i(32, 32)

	assert_vector(result.position).is_equal(expected_pos)
	assert_vector(result.chunk).is_equal(expected_chunk)

	var location3 := Location.new(Vector2i.ZERO, Vector2i.ZERO)
	add = Location.new(Vector2i(buzz.next_value() *-1, buzz.next_value()*-1), Vector2i(buzz.next_value()*-1, buzz.next_value()*-1))
	result = location3.add_location(add)
	@warning_ignore("integer_division")
	expected_chunk = location3.chunk + add.chunk - Vector2i.ONE
	expected_pos = location3.position + add.position + Vector2i(64, 64)

	assert_vector(result.chunk).is_equal(expected_chunk)
	assert_vector(result.position).is_equal(expected_pos)
