extends AreaTestBase

const FIRE_PATH := "res://resources/spells/fire.tres"


func _fire(max_hits: int = 1) -> SpellData:
	var spell := (load(FIRE_PATH) as SpellData).duplicate() as SpellData
	spell.max_hits = max_hits
	return spell


func _missile(spell: SpellData, at: Vector2 = Vector2.ZERO, direction: Vector2 = Vector2.RIGHT) -> MissileArea:
	return _launch(spell, at, direction) as MissileArea


func test_missile_moves_straight_at_spell_speed() -> void:
	var spell := _fire()
	var missile := _missile(spell)
	missile._physics_process(0.1)
	assert_almost_eq(missile.position.x, spell.projectile_speed * 0.1, 0.01)
	assert_almost_eq(missile.position.y, 0.0, 0.01)


func test_missile_freed_after_range_over_speed() -> void:
	var spell := _fire()
	var lifetime := spell.effective_range() / spell.projectile_speed
	var missile := _missile(spell)
	missile._physics_process(lifetime - 0.05)
	assert_false(missile.is_queued_for_deletion())
	missile._physics_process(0.1)
	assert_true(missile.is_queued_for_deletion())


func test_shorter_range_frees_the_missile_sooner() -> void:
	var spell := _fire()
	spell.range_scale = 0.5
	var missile := _missile(spell)
	missile._physics_process(spell.effective_range() / spell.projectile_speed + 0.05)
	assert_true(missile.is_queued_for_deletion())


func test_missile_size_scales_the_node() -> void:
	var spell := _fire()
	spell.size_scale = 2.0
	assert_eq(_missile(spell).scale, Vector2(2, 2))


func test_missile_starts_at_the_origin() -> void:
	assert_eq(_missile(_fire(), Vector2(30, 40)).global_position, Vector2(30, 40))


func test_missile_is_tinted_by_the_spell() -> void:
	var spell := _fire()
	assert_eq((_missile(spell).get_node("Body") as ColorRect).color, spell.color)


func test_hitbox_carries_spell_damage_and_knockback() -> void:
	var spell := _fire()
	var hitbox := _missile(spell).get_node("Hitbox") as HitboxComponent
	assert_eq(hitbox.damage, DamageSystem.calculate(spell.damage, spell.primary_element()))
	assert_eq(hitbox.knockback, spell.knockback)


func test_single_hit_spell_hits_one_of_two_and_is_freed() -> void:
	var first := _enemy(Vector2(0, 0))
	var second := _enemy(Vector2(2, 0))
	var missile := _missile(_fire(1), Vector2(1, 0))
	await wait_physics_frames(6)
	var damaged := 0
	for enemy in [first, second]:
		if _health(enemy).current_health < _health(enemy).max_health:
			damaged += 1
	assert_eq(damaged, 1)
	assert_false(is_instance_valid(missile))


func test_piercing_spell_hits_three_distinct_enemies_once_each() -> void:
	var spell := _fire(3)
	var enemies := [_enemy(Vector2(0, 0)), _enemy(Vector2(2, 0)), _enemy(Vector2(4, 0))]
	var missile := _missile(spell, Vector2(2, 0))
	await wait_physics_frames(8)
	for enemy in enemies:
		var health := _health(enemy)
		assert_eq(health.current_health, health.max_health - spell.damage)
	assert_false(is_instance_valid(missile))


func test_piercing_spell_survives_a_single_hit() -> void:
	var spell := _fire(3)
	var enemy := _enemy(Vector2(0, 0))
	var missile := _missile(spell, Vector2(0, 0))
	await wait_physics_frames(4)
	assert_lt(_health(enemy).current_health, _health(enemy).max_health)
	assert_true(is_instance_valid(missile))
	assert_false(missile.is_queued_for_deletion())
