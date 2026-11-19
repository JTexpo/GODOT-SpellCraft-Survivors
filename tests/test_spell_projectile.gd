extends GutTest

const FIRE_PATH := "res://resources/spells/fire.tres"
const ENEMY_SCENE := "res://scenes/enemies/base_enemy.tscn"


func _spell(max_hits: int = 1) -> SpellData:
	var spell := (load(FIRE_PATH) as SpellData).duplicate() as SpellData
	spell.max_hits = max_hits
	return spell


func _launch(spell: SpellData, direction: Vector2 = Vector2.RIGHT, at: Vector2 = Vector2.ZERO) -> SpellProjectile:
	var projectile := spell.projectile_scene.instantiate() as SpellProjectile
	add_child_autofree(projectile)
	projectile.global_position = at
	projectile.launch(direction, spell)
	return projectile


func _enemy(at: Vector2) -> Enemy:
	var enemy := (load(ENEMY_SCENE) as PackedScene).instantiate() as Enemy
	add_child_autofree(enemy)
	enemy.global_position = at
	return enemy


func _health(enemy: Enemy) -> HealthComponent:
	return enemy.get_node("HealthComponent") as HealthComponent


func test_projectile_moves_straight_at_spell_speed() -> void:
	var spell := _spell()
	var projectile := _launch(spell)
	projectile._physics_process(0.1)
	assert_almost_eq(projectile.position.x, spell.projectile_speed * 0.1, 0.01)
	assert_almost_eq(projectile.position.y, 0.0, 0.01)


func test_projectile_freed_after_lifetime() -> void:
	var spell := _spell()
	var projectile := _launch(spell)
	projectile._physics_process(spell.projectile_lifetime + 0.1)
	assert_true(projectile.is_queued_for_deletion())


func test_projectile_is_tinted_by_the_spell() -> void:
	var spell := _spell()
	var projectile := _launch(spell)
	assert_eq((projectile.get_node("Body") as ColorRect).color, spell.color)


func test_hitbox_carries_spell_damage_and_knockback() -> void:
	var spell := _spell()
	var projectile := _launch(spell)
	var hitbox := projectile.get_node("Hitbox") as HitboxComponent
	assert_eq(hitbox.damage, DamageSystem.calculate(spell.damage, spell.primary_element()))
	assert_eq(hitbox.knockback, spell.knockback)


func test_single_hit_spell_hits_one_of_two_and_is_freed() -> void:
	var first := _enemy(Vector2(0, 0))
	var second := _enemy(Vector2(2, 0))
	var projectile := _launch(_spell(1), Vector2.RIGHT, Vector2(1, 0))
	await wait_physics_frames(6)
	var damaged := 0
	for enemy in [first, second]:
		if _health(enemy).current_health < _health(enemy).max_health:
			damaged += 1
	assert_eq(damaged, 1)
	assert_false(is_instance_valid(projectile))


func test_piercing_spell_hits_three_distinct_enemies_once_each() -> void:
	var spell := _spell(3)
	var enemies := [_enemy(Vector2(0, 0)), _enemy(Vector2(2, 0)), _enemy(Vector2(4, 0))]
	var projectile := _launch(spell, Vector2.RIGHT, Vector2(2, 0))
	await wait_physics_frames(8)
	for enemy in enemies:
		var health := _health(enemy)
		assert_eq(health.current_health, health.max_health - spell.damage)
	assert_false(is_instance_valid(projectile))


func test_piercing_spell_survives_a_single_hit() -> void:
	var spell := _spell(3)
	var enemy := _enemy(Vector2(0, 0))
	var projectile := _launch(spell, Vector2.RIGHT, Vector2(0, 0))
	await wait_physics_frames(4)
	assert_lt(_health(enemy).current_health, _health(enemy).max_health)
	assert_true(is_instance_valid(projectile))
	assert_false(projectile.is_queued_for_deletion())
