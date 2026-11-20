class_name LevelToast
extends Label
## TEMPORARY (Sprint 8): "Level 4! More spell mana" shown when a level is reached. Level-ups in a row
## are listed one per line (the newest last, at most MAX_LINES) so a big XP gain does not hide the
## earlier rewards. It only processes while it is showing.

const DURATION := 2.5
const FADE := 0.5
const MAX_LINES := 4

var _lines: Array[String] = []
var _time_left: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		visible = false
		set_process(false)
		_lines.clear()
		return
	modulate.a = clampf(_time_left / FADE, 0.0, 1.0)


func show_level_up(level: int, reward: LevelReward) -> void:
	_lines.append("Level %d! %s" % [level, reward.description if reward != null else ""])
	while _lines.size() > MAX_LINES:
		_lines.pop_front()
	text = "\n".join(_lines)
	modulate.a = 1.0
	_time_left = DURATION
	visible = true
	set_process(true)


func is_showing() -> bool:
	return visible
