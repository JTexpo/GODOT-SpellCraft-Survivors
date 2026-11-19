class_name ScrollPickup
extends Area2D
## A scroll lying on the ground. Passive: only the player's PickupCollector looks for it.
## The shape depends on the category (round Base, square Area, diamond Buff), so categories
## can be told apart without colour. It stays until collected.

const BOB_HEIGHT := 1.5
const BOB_TIME := 0.7
const BASE_RADIUS := 5.0
const AREA_HALF_SIDE := 4.0
const BUFF_RADIUS := 6.0
const BASE_POINTS := 12

var scroll: ScrollData

var _collected: bool = false

@onready var _shape: Polygon2D = $Shape


func _ready() -> void:
	add_to_group(&"scroll_pickups")


func setup(scroll_data: ScrollData) -> void:
	scroll = scroll_data
	_shape.polygon = shape_points(scroll_data.category)
	_shape.color = scroll_data.color
	var bob := create_tween().set_loops()
	bob.tween_property(_shape, "position:y", -BOB_HEIGHT, BOB_TIME).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_shape, "position:y", BOB_HEIGHT, BOB_TIME).set_trans(Tween.TRANS_SINE)


## Returns the scroll the first time and null every time after.
func collect() -> ScrollData:
	if _collected:
		return null
	_collected = true
	set_deferred("monitorable", false)
	queue_free()
	return scroll


static func shape_points(category: ScrollData.Category) -> PackedVector2Array:
	match category:
		ScrollData.Category.AREA:
			var side := AREA_HALF_SIDE
			return PackedVector2Array([Vector2(-side, -side), Vector2(side, -side), Vector2(side, side), Vector2(-side, side)])
		ScrollData.Category.BUFF:
			var reach := BUFF_RADIUS
			return PackedVector2Array([Vector2(0, -reach), Vector2(reach, 0), Vector2(0, reach), Vector2(-reach, 0)])
	var points := PackedVector2Array()
	for i in BASE_POINTS:
		points.append(Vector2.from_angle(TAU * i / BASE_POINTS) * BASE_RADIUS)
	return points
