class_name XpBar
extends Control
## TEMPORARY (Sprint 8): a thin XP bar along the top of the screen with the level next to it. It
## only shows what a RunProgress reports and holds no rules.

const BAR_HEIGHT := 3.0
const TEXT_AT := Vector2(92, 5)

var _progress: RunProgress
var _track: LevelTrack
var _ratio: float = 0.0
var _level: int = 1

var _background: ColorRect
var _fill: ColorRect
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background = ColorRect.new()
	_background.color = Color(0.1, 0.1, 0.1, 0.8)
	_background.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_background.offset_bottom = BAR_HEIGHT
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_fill = ColorRect.new()
	_fill.color = Color(1.0, 0.92, 0.55)
	_fill.size = Vector2(0.0, BAR_HEIGHT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.add_child(_fill)
	_label = Label.new()
	_label.position = TEXT_AT
	_label.add_theme_font_size_override("font_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_background.resized.connect(_update_fill)
	_update()


func bind(progress: RunProgress) -> void:
	_progress = progress
	_track = progress.track
	progress.xp_changed.connect(refresh)
	refresh(progress.profile.total_xp, progress.level())


func refresh(total_xp: int, level: int) -> void:
	_level = level
	_ratio = _track.progress(total_xp) if _track != null else 0.0
	_update()


func level_text() -> String:
	if _track != null and _level >= _track.max_level():
		return "Lv %d MAX" % _level
	return "Lv %d" % _level


func fill_ratio() -> float:
	return _ratio


func _update() -> void:
	if _label == null:
		return
	_label.text = level_text()
	_update_fill()


func _update_fill() -> void:
	_fill.size = Vector2(_background.size.x * _ratio, BAR_HEIGHT)
