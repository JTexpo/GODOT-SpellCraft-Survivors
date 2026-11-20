class_name XpGem
extends Area2D
## XP lying on the ground. Passive: only the player's PickupCollector looks for it. Its value can
## grow when the dropper merges a new drop into it at the gem cap, so no XP is ever lost.

const POINTS := [Vector2(0, -4), Vector2(4, 3), Vector2(-4, 3)]
## TEMPORARY colour (placeholder art).
const COLOR := Color(1.0, 0.92, 0.55)

var value: int = 0

var _collected: bool = false

@onready var _shape: Polygon2D = $Shape


func _ready() -> void:
	add_to_group(&"xp_gems")
	_shape.polygon = PackedVector2Array(POINTS)
	_shape.color = COLOR


func setup(amount: int) -> void:
	value = amount


func add_value(amount: int) -> void:
	value += amount


## Returns the value the first time and 0 every time after.
func collect() -> int:
	if _collected:
		return 0
	_collected = true
	set_deferred("monitorable", false)
	queue_free()
	return value
