extends AreaTestBase

const WAVE := "res://resources/spells/areas/wave_area.tres"
## Enemies are clamped to the arena (no negative coordinates), so waves are cast from here.
const O := Vector2(300, 150)


func _damaged(enemy: Enemy) -> bool:
	return _health(enemy).current_health < _health(enemy).max_health


func _wave(spell: SpellData) -> WaveArea:
	return _launch(spell, O) as WaveArea


func test_wave_moves_at_spell_speed() -> void:
	var wave := _wave(_spell(WAVE))
	wave._physics_process(0.5)
	assert_almost_eq(wave.global_position.x, O.x + 70.0, 0.01)
	assert_almost_eq(wave.global_position.y, O.y, 0.01)


func test_wave_widens_while_travelling() -> void:
	var wave := _wave(_spell(WAVE))
	assert_almost_eq(wave.current_width(), 48.0, 0.01)
	wave._physics_process(0.5)
	assert_almost_eq(wave.current_width(), 60.0, 0.01)


func test_wave_ends_at_range() -> void:
	var wave := _wave(_spell(WAVE))
	wave._physics_process(120.0 / 140.0 - 0.05)
	assert_false(wave.is_queued_for_deletion())
	wave._physics_process(0.1)
	assert_true(wave.is_queued_for_deletion())


func test_shorter_range_ends_the_wave_sooner() -> void:
	var wave := _wave(_spell(WAVE, 10.0, 0.0, 0.5))
	wave._physics_process(60.0 / 140.0 + 0.05)
	assert_true(wave.is_queued_for_deletion())


func test_wave_hits_every_enemy_it_passes_once_and_keeps_going() -> void:
	var spell := _spell(WAVE)
	var enemies := [_enemy(O + Vector2(30, 0)), _enemy(O + Vector2(60, 0)), _enemy(O + Vector2(90, 0))]
	var wave := _wave(spell)
	await wait_physics_frames(40)
	for enemy in enemies:
		assert_eq(_health(enemy).current_health, _health(enemy).max_health - spell.damage)
	assert_true(is_instance_valid(wave))
	assert_false(wave.is_queued_for_deletion())


func test_wave_misses_enemies_outside_its_width() -> void:
	var outside := _enemy(O + Vector2(60, 60))
	_wave(_spell(WAVE))
	await wait_physics_frames(40)
	assert_false(_damaged(outside))


func test_wave_carries_damage_and_knockback() -> void:
	var spell := _spell(WAVE, 12.0, 100.0)
	var hitbox := _wave(spell).get_node("Hitbox") as HitboxComponent
	assert_eq(hitbox.damage, DamageSystem.calculate(spell.damage, spell.primary_element()))
	assert_eq(hitbox.knockback, 100.0)
	assert_eq(hitbox.max_hits, 0)
