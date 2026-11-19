class_name TouchJoystick
extends Control

@export var action_up: StringName = &"move_up"
@export var action_down: StringName = &"move_down"
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"
## Optional action held down for as long as the stick is touched (the aim stick uses "cast").
@export var held_action: StringName = &""
@export var radius: float = 40.0

var touch_index: int = -1
var _knob_offset: Vector2 = Vector2.ZERO


static func should_show() -> bool:
	return DisplayServer.is_touchscreen_available()


func _ready() -> void:
	visible = should_show()


func _exit_tree() -> void:
	_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or (what == NOTIFICATION_VISIBILITY_CHANGED and not visible):
		_release()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventScreenDrag:
		handle_drag(event.index, event.position)


func handle_touch(index: int, pressed: bool, screen_position: Vector2) -> void:
	if pressed:
		if touch_index == -1 and get_global_rect().has_point(screen_position):
			touch_index = index
			_update(screen_position)
	elif index == touch_index:
		_release()


func handle_drag(index: int, screen_position: Vector2) -> void:
	if index == touch_index:
		_update(screen_position)


func _update(screen_position: Vector2) -> void:
	var offset := screen_position - get_global_rect().get_center()
	var vector := (offset / radius).limit_length(1.0)
	_knob_offset = vector * radius
	_set_action(action_right, maxf(vector.x, 0.0))
	_set_action(action_left, maxf(-vector.x, 0.0))
	_set_action(action_down, maxf(vector.y, 0.0))
	_set_action(action_up, maxf(-vector.y, 0.0))
	if held_action != &"":
		Input.action_press(held_action)
	queue_redraw()


func _release() -> void:
	touch_index = -1
	_knob_offset = Vector2.ZERO
	for action in [action_up, action_down, action_left, action_right, held_action]:
		if action != &"":
			Input.action_release(action)
	queue_redraw()


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	var center := size / 2.0
	draw_arc(center, radius, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
	draw_circle(center + _knob_offset, radius * 0.4, Color(1, 1, 1, 0.5))
