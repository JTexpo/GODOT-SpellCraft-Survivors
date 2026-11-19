extends GutTest

var _stick: TouchJoystick
var _center: Vector2


func before_each() -> void:
	_stick = TouchJoystick.new()
	_stick.size = Vector2(96, 96)
	_stick.position = Vector2(100, 100)
	add_child_autofree(_stick)
	_center = _stick.get_global_rect().get_center()


func after_each() -> void:
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"aim_up", &"aim_down", &"aim_left", &"aim_right", &"cast"]:
		Input.action_release(action)


func _vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func test_drag_right_presses_move_right() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius, 0))
	assert_almost_eq(_vector(), Vector2.RIGHT, Vector2(0.01, 0.01))


func test_drag_beyond_radius_is_clamped() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius * 5.0, _stick.radius * 5.0))
	assert_lte(_vector().length(), 1.001)


func test_release_clears_all_movement() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(0, _stick.radius))
	_stick.handle_touch(0, false, _center)
	assert_eq(_vector(), Vector2.ZERO)
	assert_eq(_stick.touch_index, -1)


func test_second_finger_ignored_while_first_held() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius, 0))
	var before := _vector()
	_stick.handle_touch(1, true, _center + Vector2(0, 20))
	_stick.handle_drag(1, _center + Vector2(0, _stick.radius))
	assert_eq(_vector(), before)
	_stick.handle_touch(1, false, _center)
	assert_eq(_vector(), before)


func test_hiding_while_held_clears_movement() -> void:
	_stick.show()
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius, 0))
	_stick.hide()
	assert_eq(_vector(), Vector2.ZERO)
	assert_eq(_stick.touch_index, -1)


func test_pause_while_held_clears_movement() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius, 0))
	_stick.notification(Node.NOTIFICATION_PAUSED)
	assert_eq(_vector(), Vector2.ZERO)
	assert_eq(_stick.touch_index, -1)


func test_touch_outside_control_ignored() -> void:
	_stick.handle_touch(0, true, _center + Vector2(500, 500))
	assert_eq(_stick.touch_index, -1)
	assert_eq(_vector(), Vector2.ZERO)


func test_touch_controls_hidden_without_touchscreen() -> void:
	var controls: Node = load("res://scenes/ui/touch_controls.tscn").instantiate()
	add_child_autofree(controls)
	var stick := controls.get_node("TouchJoystick") as TouchJoystick
	assert_eq(stick.visible, TouchJoystick.should_show())


func _make_aim_stick() -> TouchJoystick:
	var stick := TouchJoystick.new()
	stick.action_up = &"aim_up"
	stick.action_down = &"aim_down"
	stick.action_left = &"aim_left"
	stick.action_right = &"aim_right"
	stick.held_action = &"cast"
	stick.size = Vector2(96, 96)
	stick.position = Vector2(300, 100)
	add_child_autofree(stick)
	return stick


func test_aim_stick_presses_aim_actions_and_cast() -> void:
	var aim_stick := _make_aim_stick()
	var center := aim_stick.get_global_rect().get_center()
	aim_stick.handle_touch(0, true, center)
	aim_stick.handle_drag(0, center + Vector2(aim_stick.radius, 0))
	var aim := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	assert_almost_eq(aim, Vector2.RIGHT, Vector2(0.01, 0.01))
	assert_true(Input.is_action_pressed(&"cast"))
	assert_eq(_vector(), Vector2.ZERO, "aim stick must not move the player")


func test_release_clears_cast() -> void:
	var aim_stick := _make_aim_stick()
	var center := aim_stick.get_global_rect().get_center()
	aim_stick.handle_touch(0, true, center)
	aim_stick.handle_touch(0, false, center)
	assert_false(Input.is_action_pressed(&"cast"))


func test_default_instance_still_drives_move_actions_and_not_cast() -> void:
	_stick.handle_touch(0, true, _center)
	_stick.handle_drag(0, _center + Vector2(_stick.radius, 0))
	assert_almost_eq(_vector(), Vector2.RIGHT, Vector2(0.01, 0.01))
	assert_false(Input.is_action_pressed(&"cast"))


func test_hiding_clears_held_action() -> void:
	var aim_stick := _make_aim_stick()
	aim_stick.show()
	var center := aim_stick.get_global_rect().get_center()
	aim_stick.handle_touch(0, true, center)
	aim_stick.hide()
	assert_false(Input.is_action_pressed(&"cast"))
