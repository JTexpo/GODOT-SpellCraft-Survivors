extends GutTest

var _screen: BuffPickScreen
var _options: Array[ScrollData]


func _scroll(name: String) -> ScrollData:
	return load("res://resources/scrolls/buff/%s.tres" % name) as ScrollData


func before_each() -> void:
	_screen = load("res://scenes/ui/buff_pick_screen.tscn").instantiate() as BuffPickScreen
	_screen.pause_tree = false
	add_child_autofree(_screen)
	_options = [_scroll("damage"), _scroll("max_mana"), _scroll("duplicate_area")]


func test_starts_closed_and_hidden() -> void:
	assert_false(_screen.is_open())
	assert_false(_screen.visible)


func test_open_builds_one_button_per_option() -> void:
	_screen.open(_options, "Choose a buff")
	assert_true(_screen.is_open())
	assert_true(_screen.visible)
	assert_eq(_screen.option_count(), 3)
	assert_eq(_screen.button_text(0).split("\n")[0], "Increased Damage")


func test_open_pauses_the_tree_and_choose_resumes_it() -> void:
	_screen.pause_tree = true
	_screen.open(_options, "Choose a buff")
	assert_true(get_tree().paused)
	_screen.choose(1)
	assert_false(get_tree().paused)
	assert_false(_screen.is_open())


func test_choose_emits_the_scroll_and_closes() -> void:
	watch_signals(_screen)
	_screen.open(_options, "Choose a buff")
	_screen.choose(2)
	assert_signal_emitted_with_parameters(_screen, "chosen", [_options[2]])
	assert_false(_screen.is_open())
	assert_false(_screen.visible)


func test_choose_out_of_range_is_ignored() -> void:
	watch_signals(_screen)
	_screen.open(_options, "Choose a buff")
	_screen.choose(3)
	_screen.choose(-1)
	assert_signal_not_emitted(_screen, "chosen")
	assert_true(_screen.is_open())


func test_choose_while_closed_does_nothing() -> void:
	watch_signals(_screen)
	_screen.choose(0)
	assert_signal_not_emitted(_screen, "chosen")


func test_cancel_does_nothing() -> void:
	_screen.open(_options, "Choose a buff")
	for action in [&"ui_cancel", &"pause"]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = true
		_screen._unhandled_input(event)
	assert_true(_screen.is_open())


func test_empty_options_do_not_open_or_pause() -> void:
	_screen.pause_tree = true
	_screen.open([] as Array[ScrollData], "Choose a buff")
	assert_false(_screen.is_open())
	assert_false(get_tree().paused)


func test_first_option_has_focus_for_keyboard_and_controller() -> void:
	_screen.open(_options, "Choose a buff")
	await wait_process_frames(1)
	assert_true(_screen.first_button_has_focus())


func test_reopening_replaces_the_old_buttons() -> void:
	_screen.open(_options, "Choose a buff")
	_screen.choose(0)
	_screen.open([_options[0]] as Array[ScrollData], "Choose a buff")
	assert_eq(_screen.option_count(), 1)


func test_effect_text_names_the_buff_numbers() -> void:
	var damage := BuffPickScreen.effect_text(_scroll("damage"))
	assert_string_contains(damage, "damage x1.5")
	assert_string_contains(damage, "cost x1.5")
	var copies := BuffPickScreen.effect_text(_scroll("duplicate_area"))
	assert_string_contains(copies, "+1 copy")
	assert_string_contains(copies, "cost x2")
	assert_string_contains(BuffPickScreen.effect_text(_scroll("max_mana")), "mana pool x1.5")
	assert_string_contains(BuffPickScreen.effect_text(_scroll("ignore_resistance")), "ignores resistance")
	assert_string_contains(BuffPickScreen.effect_text(_scroll("double_vulnerability")), "strong-hit bonus")


func test_touch_event_is_bridged_while_open() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(40, 40)
	assert_false(_screen.handle_input(touch), "closed")
	_screen.open(_options, "Choose a buff")
	assert_true(_screen.handle_input(touch), "open")
	assert_false(_screen.handle_input(InputEventScreenDrag.new()), "only touches are bridged")
