extends GutTest

var _aim: AimComponent


func before_each() -> void:
	_aim = AimComponent.new()
	add_child_autofree(_aim)


func test_mouse_aims_from_origin_to_cursor() -> void:
	_aim.update_aim(Vector2(10, 10), Vector2(10, 50), Vector2.ZERO, false, true)
	assert_eq(_aim.aim_direction, Vector2.DOWN)
	assert_eq(_aim.source, AimComponent.Source.MOUSE)


func test_stick_overrides_mouse_while_held() -> void:
	_aim.update_aim(Vector2.ZERO, Vector2(100, 0), Vector2(0, -1), false, true)
	assert_eq(_aim.aim_direction, Vector2.UP)
	assert_eq(_aim.source, AimComponent.Source.STICK)


func test_mouse_takes_over_after_stick_released_and_moved() -> void:
	_aim.update_aim(Vector2.ZERO, Vector2(100, 0), Vector2(0, -1), false, false)
	_aim.update_aim(Vector2.ZERO, Vector2(100, 0), Vector2.ZERO, false, false)
	assert_eq(_aim.aim_direction, Vector2.UP, "an idle mouse must not override the stick's last aim")
	_aim.update_aim(Vector2.ZERO, Vector2(100, 0), Vector2.ZERO, false, true)
	assert_eq(_aim.aim_direction, Vector2.RIGHT)
	assert_eq(_aim.source, AimComponent.Source.MOUSE)


func test_zero_length_mouse_keeps_previous_direction() -> void:
	_aim.update_aim(Vector2.ZERO, Vector2(0, -50), Vector2.ZERO, false, true)
	_aim.update_aim(Vector2(5, 5), Vector2(5, 5), Vector2.ZERO, false, true)
	assert_eq(_aim.aim_direction, Vector2.UP)
	assert_false(is_nan(_aim.aim_direction.x))


func test_firing_flag_follows_input() -> void:
	_aim.update_aim(Vector2.ZERO, Vector2(1, 0), Vector2.ZERO, true, true)
	assert_true(_aim.is_firing)
	_aim.update_aim(Vector2.ZERO, Vector2(1, 0), Vector2.ZERO, false, true)
	assert_false(_aim.is_firing)


func test_mouse_aim_point_is_the_cursor() -> void:
	_aim.update_aim(Vector2(10, 10), Vector2(10, 50), Vector2.ZERO, false, true)
	assert_eq(_aim.aim_point, Vector2(10, 50))


func test_stick_aim_point_is_far_along_the_direction() -> void:
	_aim.update_aim(Vector2(5, 5), Vector2(100, 0), Vector2(0, -1), false, true)
	assert_eq(_aim.aim_point, Vector2(5, 5) + Vector2.UP * AimComponent.FAR_DISTANCE)


func test_stick_aim_point_follows_the_origin_after_release() -> void:
	_aim.update_aim(Vector2(5, 5), Vector2(100, 0), Vector2(0, -1), false, true)
	_aim.update_aim(Vector2(50, 0), Vector2(100, 0), Vector2.ZERO, false, false)
	assert_eq(_aim.aim_point, Vector2(50, 0) + Vector2.UP * AimComponent.FAR_DISTANCE)


func test_mouse_exactly_on_the_player_keeps_a_finite_aim_point() -> void:
	_aim.update_aim(Vector2(5, 5), Vector2(5, 5), Vector2.ZERO, false, true)
	assert_eq(_aim.aim_point, Vector2(5, 5))
	assert_true(_aim.aim_point.is_finite())
