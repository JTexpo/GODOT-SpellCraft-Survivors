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


func test_run_summary_text_shows_xp_and_level() -> void:
	_screen.set_run_summary(120, 7)
	assert_eq(_screen.summary_text(), "+120 XP, +0 Gold this run, level 7")


func test_death_screen_without_a_summary_shows_no_extra_line() -> void:
	_screen.show_death()
	assert_eq(_screen.summary_text(), "")


func test_restart_still_works_with_a_summary() -> void:
	_screen.set_run_summary(5, 1)
	_screen.show_death()
	watch_signals(_screen)
	_screen.handle_event(_restart_action())
	assert_signal_emitted(_screen, "restart_requested")


func test_summary_includes_gold() -> void:
	_screen.set_run_summary(120, 7, 45)
	assert_eq(_screen.summary_text(), "+120 XP, +45 Gold this run, level 7")
