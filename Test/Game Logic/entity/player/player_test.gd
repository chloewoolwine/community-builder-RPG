class_name PlayerTest
extends GdUnitTestSuite

@warning_ignore("unused_parameter")
func test_basic_input(key:Key, direction: Vector2, test_parameters := [
	[KEY_A, Vector2.LEFT],
	[KEY_D, Vector2.RIGHT],
	[KEY_W, Vector2.UP],
	[KEY_S, Vector2.DOWN]
]) -> void:
	var runner := scene_runner("res://Test/misc/player_movement_test.tscn")
	var player:Player = runner.find_child("Player")

	player.loading_done()
	await await_millis(10)
	
	var start_pos:Vector2 = player.global_position
	runner.simulate_key_press(key)
	await await_millis(500)
	runner.simulate_key_release(key)
	var end_pos:Vector2 = player.global_position

	var movement_direction:Vector2 = start_pos.direction_to(end_pos)
	assert_vector(movement_direction).is_equal_approx(direction, Vector2(.1, .1))
	await await_millis(500)


func test_jump() -> void: 
	var runner := scene_runner("res://Test/misc/player_movement_test.tscn")
	var player:Player = runner.find_child("Player")

	player.loading_done()
	await await_millis(10)
	
	var start_pos:Vector2 = player.global_position
	runner.simulate_key_press(KEY_SPACE)
	await await_millis(500)
	runner.simulate_key_release(KEY_SPACE)
	var end_pos:Vector2 = player.global_position

	assert_vector(start_pos).is_equal_approx(end_pos, Vector2(.1, .1))
	await await_millis(500)

	var key:Key = calculate_dir(player, runner, Vector2(388, 125))
	while !player.global_position.is_equal_approx(Vector2(388, 125)):
		await await_millis(100) 
	runner.simulate_key_release(key)

func calculate_dir(player: Player, runner: GdUnitSceneRunner, target: Vector2) -> Key: #im doing this in lieue of making a player controller node inside of player-
	#mainly becaue i didnt feel like it and it doesn't seem that productive to have 
	var direction := player.global_position.direction_to(target)
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			#direction is down
			runner.simulate_key_press(KEY_S)
			return KEY_S
		else:
			runner.simulate_key_press(KEY_W)
			return KEY_W
	else:
		if direction.x > 0:
			#right
			runner.simulate_key_press(KEY_D)
			return KEY_D
		else:
			runner.simulate_key_press(KEY_A)
			return KEY_A
