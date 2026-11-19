class_name InteractButton
extends Control
## TEMPORARY (Sprint 6): an on-screen "use" button for touch screens. It appears only while the
## player is next to something to interact with. Handles touches itself (mouse emulation is off)
## and ignores mouse clicks, like the other touch widgets.

signal pressed

const SIZE := Vector2(40, 16)

## Desktop players press E, so the button normally only shows on a touchscreen.
@export var require_touchscreen: bool = true

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	var background := ColorRect.new()
	background.size = SIZE
	background.color = Color(0.1, 0.1, 0.12, 0.85)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_label = Label.new()
	_label.text = "Use"
	_label.position = Vector2(10, 1)
	_label.add_theme_font_size_override("font_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if handle_touch(event.position):
			get_viewport().set_input_as_handled()


func handle_touch(screen_position: Vector2) -> bool:
	if not is_visible_in_tree() or not get_global_rect().has_point(screen_position):
		return false
	pressed.emit()
	return true


func set_available(available: bool) -> void:
	visible = available and (not require_touchscreen or TouchJoystick.should_show())
