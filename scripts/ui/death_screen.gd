class_name DeathScreen
extends CanvasLayer
## TEMPORARY (Sprint 1): simple "You died" overlay. A real game-over flow comes later.

signal restart_requested

## Ignore restart input for this long after dying, so a held button doesn't skip the screen.
var input_delay_msec: int = 500
var restart_scene_path: String = ""

var _shown_at_msec: int = 0

@onready var _summary: Label = $Summary


func _ready() -> void:
	visible = false
	_summary.visible = false


## Listens in _input, which runs before any control sees the event. _unhandled_input would never hear
## a tap that a control under the finger swallowed, and a screen-sized control would silently break
## "tap to restart" on a phone.
func _input(event: InputEvent) -> void:
	handle_event(event)


## Adds a line under "You died": the XP gained this run and the level reached.
func set_run_summary(run_xp: int, level: int) -> void:
	_summary.text = "+%d XP this run, level %d" % [run_xp, level]
	_summary.visible = true


## The summary line, or "" if none was set.
func summary_text() -> String:
	return _summary.text if _summary.visible else ""


func show_death() -> void:
	if restart_scene_path.is_empty() and get_tree().current_scene != null:
		restart_scene_path = get_tree().current_scene.scene_file_path
	_shown_at_msec = Time.get_ticks_msec()
	visible = true


func handle_event(event: InputEvent) -> void:
	if not visible or Time.get_ticks_msec() - _shown_at_msec < input_delay_msec:
		return
	var touched := false
	if event is InputEventScreenTouch:
		touched = event.pressed
	if touched or event.is_action_pressed(&"restart"):
		restart_requested.emit()
		restart()


func restart() -> Error:
	return SceneSwitcher.change_to(get_tree(), restart_scene_path)
