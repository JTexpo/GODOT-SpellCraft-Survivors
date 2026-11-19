class_name SpellSlotWidget
extends Control
## TEMPORARY (Sprint 2): one slot in the placeholder spell bar. Shows the spell's colour, its
## mana and whether it is selected. Taps on a touchscreen select it. Mouse clicks are ignored
## on purpose, so clicking here never casts. Build children in _ready, so add it to the tree
## before calling setup().

signal pressed(index: int)

const SIZE := Vector2(28, 18)
const FLASH_TIME := 0.25
const DEPLETED_TINT := Color(0.4, 0.4, 0.4, 1)

var slot_index: int = 0
var empty: bool = true
var locked: bool = false
var element_color: Color = Color.WHITE
var ratio: float = 0.0
var depleted: bool = false
var selected: bool = false

var _flash_left: float = 0.0

var _highlight: ColorRect
var _background: ColorRect
var _swatch: ColorRect
var _fill: ColorRect
var _label: Label


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight = _add_rect(Vector2(-1, -1), SIZE + Vector2(2, 2), Color.WHITE)
	_background = _add_rect(Vector2.ZERO, SIZE, Color(0.1, 0.1, 0.12, 0.85))
	_swatch = _add_rect(Vector2(1, 1), Vector2(SIZE.x - 2, 10), Color.WHITE)
	_fill = _add_rect(Vector2(1, 13), Vector2(SIZE.x - 2, 4), Color(0.4, 0.7, 1.0))
	_label = Label.new()
	_label.position = Vector2(2, -1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 8)
	add_child(_label)
	set_process(false)
	_refresh()


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _flash_left <= 0.0:
		set_process(false)
	_refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if handle_touch(event.position):
			get_viewport().set_input_as_handled()


func handle_touch(screen_position: Vector2) -> bool:
	if locked or not is_visible_in_tree() or not get_global_rect().has_point(screen_position):
		return false
	pressed.emit(slot_index)
	return true


## A null spell means an empty slot.
func setup(index: int, spell: SpellData) -> void:
	slot_index = index
	empty = spell == null
	element_color = spell.color if spell != null else Color.WHITE
	ratio = 0.0 if spell == null else 1.0
	_label.text = str(index + 1)
	_refresh()


## A locked slot is dimmed, marked "x", and ignores taps.
func set_locked(value: bool) -> void:
	locked = value
	_refresh()


func set_mana(current: float, maximum: float) -> void:
	ratio = current / maximum if maximum > 0.0 else 0.0
	# The widget only knows ratios, so "depleted" means nothing is left at all.
	depleted = current <= 0.0
	_refresh()


func set_selected(value: bool) -> void:
	selected = value
	_refresh()


func flash_dry() -> void:
	_flash_left = FLASH_TIME
	set_process(true)
	_refresh()


func is_flashing() -> bool:
	return _flash_left > 0.0


func _refresh() -> void:
	if _background == null:
		return
	_highlight.visible = selected
	modulate.a = 0.2 if locked else (0.35 if empty else 1.0)
	_label.text = "x" if locked else str(slot_index + 1)
	_swatch.color = DEPLETED_TINT if depleted else element_color
	_fill.size.x = (SIZE.x - 2) * ratio
	_background.color = Color(0.6, 0.1, 0.1, 0.9) if is_flashing() else Color(0.1, 0.1, 0.12, 0.85)


func _add_rect(rect_position: Vector2, rect_size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = rect_position
	rect.size = rect_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect
