extends GutTest

var _screen: DeathScreen


func before_each() -> void:
	_screen = load("res://scenes/ui/death_screen.tscn").instantiate() as DeathScreen
	add_child_autofree(_screen)
	_screen.input_delay_msec = 0


func _restart_action() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"restart"
	event.pressed = true
	return event


func _touch() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


func test_hidden_until_shown() -> void:
	assert_false(_screen.visible)
	_screen.show_death()
	assert_true(_screen.visible)


func test_restart_ignored_while_hidden() -> void:
	watch_signals(_screen)
	_screen.handle_event(_restart_action())
	assert_signal_not_emitted(_screen, "restart_requested")


func test_restart_requested_on_action_and_on_touch_when_shown() -> void:
	watch_signals(_screen)
	_screen.show_death()
	_screen.handle_event(_restart_action())
	_screen.handle_event(_touch())
	assert_signal_emit_count(_screen, "restart_requested", 2)


func test_input_ignored_during_short_delay_after_death() -> void:
	_screen.input_delay_msec = 60000
	watch_signals(_screen)
	_screen.show_death()
	_screen.handle_event(_touch())
	assert_signal_not_emitted(_screen, "restart_requested")


func test_restart_with_missing_path_fails_safely_every_time() -> void:
	_screen.restart_scene_path = "res://nope.tscn"
	assert_eq(_screen.restart(), ERR_FILE_NOT_FOUND)
	assert_eq(_screen.restart(), ERR_FILE_NOT_FOUND)
	_screen.restart_scene_path = ""
	assert_eq(_screen.restart(), ERR_FILE_NOT_FOUND)
