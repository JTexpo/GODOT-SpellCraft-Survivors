class_name GoldCounter
extends Label
## TEMPORARY (Sprint 9): "Gold 120" under the level text. It only shows what a RunProgress reports
## and holds no rules.

var _gold: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_color", Color(1.0, 0.72, 0.1))
	text = gold_text()


func bind(progress: RunProgress) -> void:
	progress.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(progress.profile.gold)


func gold_text() -> String:
	return "Gold %d" % _gold


func _on_gold_changed(total_gold: int) -> void:
	_gold = total_gold
	text = gold_text()
