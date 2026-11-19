extends GutTest


func _make(max_hp: float = 10.0) -> HealthComponent:
	var c := HealthComponent.new()
	c.max_health = max_hp
	add_child_autofree(c)
	return c


func test_starts_at_max() -> void:
	var c := _make()
	assert_eq(c.current_health, 10.0)


func test_damage_reduces_health_and_emits_changed() -> void:
	var c := _make()
	watch_signals(c)
	c.take_damage(3.0)
	assert_eq(c.current_health, 7.0)
	assert_signal_emitted_with_parameters(c, "health_changed", [7.0, 10.0])


func test_damage_clamps_at_zero_and_emits_died_once() -> void:
	var c := _make()
	watch_signals(c)
	c.take_damage(100.0)
	c.take_damage(100.0)
	assert_eq(c.current_health, 0.0)
	assert_true(c.is_dead())
	assert_signal_emit_count(c, "died", 1)


func test_heal_clamps_at_max() -> void:
	var c := _make()
	c.take_damage(4.0)
	c.heal(100.0)
	assert_eq(c.current_health, 10.0)


func test_non_positive_amounts_ignored() -> void:
	var c := _make()
	c.take_damage(4.0)
	watch_signals(c)
	c.take_damage(0.0)
	c.take_damage(-5.0)
	c.heal(-5.0)
	assert_eq(c.current_health, 6.0)
	assert_signal_not_emitted(c, "health_changed")


func test_heal_after_death_ignored() -> void:
	var c := _make()
	c.take_damage(100.0)
	c.heal(5.0)
	assert_eq(c.current_health, 0.0)
	assert_true(c.is_dead())


func test_set_max_health_resets_current() -> void:
	var c := _make()
	c.take_damage(4.0)
	c.set_max_health(50.0)
	assert_eq(c.max_health, 50.0)
	assert_eq(c.current_health, 50.0)
