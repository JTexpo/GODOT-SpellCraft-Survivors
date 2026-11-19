extends GutTest


func _make() -> KnockbackComponent:
	var k := KnockbackComponent.new()
	add_child_autofree(k)
	return k


func test_impulse_sets_velocity() -> void:
	var k := _make()
	k.apply_impulse(Vector2(5, 0), 100.0)
	assert_eq(k.velocity, Vector2(100, 0))


func test_update_returns_current_then_decays_to_exactly_zero() -> void:
	var k := _make()
	k.apply_impulse(Vector2.RIGHT, 100.0)
	assert_eq(k.update(1.0), Vector2(100, 0))
	assert_eq(k.velocity, Vector2.ZERO)


func test_partial_decay_keeps_direction() -> void:
	var k := _make()
	k.apply_impulse(Vector2.LEFT, 100.0)
	k.update(0.1)
	assert_almost_eq(k.velocity.x, -40.0, 0.01)
	assert_eq(k.velocity.y, 0.0)


func test_zero_direction_and_non_positive_strength_ignored() -> void:
	var k := _make()
	k.apply_impulse(Vector2.ZERO, 100.0)
	k.apply_impulse(Vector2.RIGHT, 0.0)
	k.apply_impulse(Vector2.RIGHT, -5.0)
	assert_eq(k.velocity, Vector2.ZERO)
