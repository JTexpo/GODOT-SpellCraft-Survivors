extends GutTest

const ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"interact", &"pause", &"cast",
	&"spell_slot_1", &"spell_slot_2", &"spell_slot_3", &"spell_slot_4", &"spell_slot_5",
]
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]


func _has_event(action: StringName, type: Variant) -> bool:
	for event in InputMap.action_get_events(action):
		if is_instance_of(event, type):
			return true
	return false


func test_all_actions_exist() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_movement_has_keyboard_and_joypad_events() -> void:
	for action in MOVE_ACTIONS:
		assert_true(_has_event(action, InputEventKey), "%s has no key" % action)
		var joypad := _has_event(action, InputEventJoypadMotion) or _has_event(action, InputEventJoypadButton)
		assert_true(joypad, "%s has no joypad event" % action)


func test_cast_is_left_mouse_button() -> void:
	var found := false
	for event in InputMap.action_get_events(&"cast"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			found = true
	assert_true(found)
