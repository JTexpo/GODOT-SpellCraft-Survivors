class_name HitFlashComponent
extends Node

@export var target: CanvasItem
@export var duration: float = 0.1
@export var flash_color: Color = Color(2, 2, 2, 1)

var is_flashing: bool = false
var _time_left: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_stop()


func flash() -> void:
	if target == null:
		return
	target.modulate = flash_color
	_time_left = duration
	is_flashing = true
	set_process(true)


func _stop() -> void:
	if target != null:
		target.modulate = Color.WHITE
	is_flashing = false
	set_process(false)
