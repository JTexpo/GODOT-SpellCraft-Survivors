class_name CastPattern
extends RefCounted
## Turns one cast into a list of shots. A spell with more than one copy (Duplicate Area) fires a
## ring of them, and this is the only place that knows how. Areas just receive a direction and a
## target through the usual launch call, so no Area is edited for Duplicate Area.
##
## Aimed Areas: the copies are spaced evenly around the player, with copy 0 on the aim.
## Ground-targeted Areas (needs_ground_target): copy 0 lands on the chosen spot and the others sit
## in a ring around it. A spell with fewer than 2 copies is a single plain shot.

## How far the extra zones sit from the first one, in zone radii.
const GROUND_RING_RADIUS_FACTOR := 1.5


static func shots(spell: SpellData, origin: Vector2, direction: Vector2, target: Vector2) -> Array[CastShot]:
	var result: Array[CastShot] = []
	var copies := maxi(spell.copies, 1)
	if spell.area_data != null and spell.area_data.needs_ground_target:
		_ground_ring(result, spell, copies, origin, direction, target)
	else:
		_aimed_ring(result, copies, origin, direction, target)
	return result


static func _aimed_ring(result: Array[CastShot], copies: int, origin: Vector2, direction: Vector2, target: Vector2) -> void:
	var reach := (target - origin).length()
	for i in copies:
		var shot := CastShot.new()
		shot.direction = direction.rotated(TAU * i / copies)
		shot.target = target if copies == 1 else origin + shot.direction * reach
		result.append(shot)


static func _ground_ring(result: Array[CastShot], spell: SpellData, copies: int, origin: Vector2, direction: Vector2, target: Vector2) -> void:
	var center := spell.clamp_target(origin, target)
	var first := CastShot.new()
	first.direction = direction
	first.target = center
	result.append(first)
	var radius := spell.effective_size() * GROUND_RING_RADIUS_FACTOR
	for i in range(1, copies):
		var shot := CastShot.new()
		shot.direction = direction
		shot.target = center + Vector2.from_angle(direction.angle() + TAU * (i - 1) / (copies - 1)) * radius
		result.append(shot)
