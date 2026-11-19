class_name InventoryButton
extends Control
## TEMPORARY (Sprint 5): a small touch button that opens the inventory panel and shows how many
## scrolls are held. Handles touches itself (mouse emulation is off) and ignores mouse clicks.

signal pressed

const SIZE := Vector2(28, 14)

var total: int = 0

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
	_label.position = Vector2(2, -1)
	_label.add_theme_font_size_override("font_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if handle_touch(event.position):
			get_viewport().set_input_as_handled()


func handle_touch(screen_position: Vector2) -> bool:
	if not is_visible_in_tree() or not get_global_rect().has_point(screen_position):
		return false
	pressed.emit()
	return true


func set_total(value: int) -> void:
	total = value
	_refresh()


func label_text() -> String:
	return _label.text if _label != null else ""


func _refresh() -> void:
	if _label != null:
		_label.text = "I %d" % total
