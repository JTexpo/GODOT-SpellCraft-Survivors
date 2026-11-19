extends GutTest


func test_touch_becomes_a_left_mouse_press() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(120, 80)
	var mouse := TouchBridge.to_mouse_button(touch)
	assert_eq(mouse.button_index, MOUSE_BUTTON_LEFT)
	assert_true(mouse.pressed)
	assert_eq(mouse.position, Vector2(120, 80))
	assert_eq(mouse.global_position, Vector2(120, 80))
	assert_eq(mouse.button_mask, MOUSE_BUTTON_MASK_LEFT)


func test_release_becomes_a_left_mouse_release() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = false
	touch.position = Vector2(5, 6)
	var mouse := TouchBridge.to_mouse_button(touch)
	assert_eq(mouse.button_index, MOUSE_BUTTON_LEFT)
	assert_false(mouse.pressed)
	assert_eq(mouse.position, Vector2(5, 6))
	assert_eq(mouse.button_mask, 0)
