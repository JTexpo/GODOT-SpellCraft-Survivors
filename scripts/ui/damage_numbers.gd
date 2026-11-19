class_name DamageNumbers
extends Node2D
## TEMPORARY look (Sprint 4): floating damage numbers. One node draws every number from a fixed
## pool in a single _draw, so a crowd fight creates no nodes. Neutral hits are white, vulnerable
## hits larger, yellow and marked "!", resisted hits smaller and grey. It only processes and
## redraws while numbers are alive. When the pool is full the oldest number is replaced.

const POOL_SIZE := 64
const LIFETIME := 0.6
const RISE := 18.0
const LABEL_WIDTH := 40.0

const NEUTRAL_STYLE := {"color": Color.WHITE, "size": 8, "suffix": ""}
const VULNERABLE_STYLE := {"color": Color(1, 0.9, 0.2), "size": 12, "suffix": "!"}
const RESISTED_STYLE := {"color": Color(0.6, 0.6, 0.6), "size": 6, "suffix": ""}

## Oldest first. Each entry: position (global), text, style, age.
var _numbers: Array[Dictionary] = []


func _ready() -> void:
	z_index = 10
	set_process(false)


func _process(delta: float) -> void:
	for i in range(_numbers.size() - 1, -1, -1):
		_numbers[i]["age"] += delta
		if _numbers[i]["age"] >= LIFETIME:
			_numbers.remove_at(i)
	if _numbers.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for number in _numbers:
		var progress: float = number["age"] / LIFETIME
		var style: Dictionary = number["style"]
		var color: Color = style["color"]
		color.a = 1.0 - progress * progress
		var at: Vector2 = to_local(number["position"]) + Vector2(-LABEL_WIDTH * 0.5, -RISE * progress)
		draw_string(font, at, number["text"], HORIZONTAL_ALIGNMENT_CENTER, LABEL_WIDTH, style["size"], color)


## `world_position` is global. `effect` is an ElementTable.Effect.
func show_number(world_position: Vector2, amount: float, effect: int) -> void:
	var style := style_for(effect)
	if _numbers.size() >= POOL_SIZE:
		_numbers.remove_at(0)
	_numbers.append({
		"position": world_position,
		"text": str(maxi(roundi(amount), 1)) + style["suffix"],
		"style": style,
		"age": 0.0,
	})
	set_process(true)
	queue_redraw()


func active_count() -> int:
	return _numbers.size()


func active_texts() -> Array[String]:
	var texts: Array[String] = []
	for number in _numbers:
		texts.append(number["text"])
	return texts


static func style_for(effect: int) -> Dictionary:
	match effect:
		ElementTable.Effect.VULNERABLE:
			return VULNERABLE_STYLE
		ElementTable.Effect.RESISTED:
			return RESISTED_STYLE
	return NEUTRAL_STYLE
