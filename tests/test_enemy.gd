extends GutTest


func _make_enemy() -> Enemy:
	var enemy := load("res://scenes/enemies/base_enemy.tscn").instantiate() as Enemy
	add_child_autofree(enemy)
	enemy.global_position = Vector2.ZERO
	return enemy


func test_direction_points_at_player() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.add_to_group(&"player")
	player.global_position = Vector2(100, 0)
	var enemy := _make_enemy()
	assert_eq(enemy.direction_to_target(), Vector2.RIGHT)


func test_no_player_returns_zero() -> void:
	var enemy := _make_enemy()
	assert_eq(enemy.direction_to_target(), Vector2.ZERO)


func _data() -> EnemyData:
	return load("res://resources/enemies/basic_enemy.tres") as EnemyData


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_enemy_is_not_a_physics_body() -> void:
	var enemy := _make_enemy()
	assert_false(is_instance_of(enemy, CharacterBody2D))


func test_setup_applies_data_and_speed_variation_bounds() -> void:
	var data := _data()
	for seed_value in 30:
		var enemy := _make_enemy()
		enemy.setup(data, Rect2(0, 0, 960, 540), _rng(seed_value))
		assert_between(enemy.speed, data.speed * (1.0 - data.speed_variation), data.speed * (1.0 + data.speed_variation))
		assert_eq((enemy.get_node("HealthComponent") as HealthComponent).max_health, data.max_health)
		assert_eq((enemy.get_node("ContactHitbox") as HitboxComponent).damage, data.contact_damage)


func test_offset_within_radius() -> void:
	var data := _data()
	for seed_value in 30:
		var enemy := _make_enemy()
		enemy.setup(data, Rect2(0, 0, 960, 540), _rng(seed_value))
		assert_lte(enemy.target_offset.length(), data.offset_radius + 0.001)


func test_movement_clamped_to_bounds() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.add_to_group(&"player")
	player.global_position = Vector2(500, 500)
	var enemy := _make_enemy()
	enemy.setup(_data(), Rect2(0, 0, 100, 100), _rng(1))
	enemy.global_position = Vector2(150, 150)
	await wait_physics_frames(2)
	assert_lte(enemy.global_position.x, 100.0)
	assert_lte(enemy.global_position.y, 100.0)


func test_death_emits_once_and_boxes_deactivate() -> void:
	var enemy := _make_enemy()
	watch_signals(enemy)
	var hurtbox := enemy.get_node("HurtboxComponent") as HurtboxComponent
	hurtbox.receive_hit(1000.0, Vector2.ZERO)
	hurtbox.receive_hit(1000.0, Vector2.ZERO)
	await wait_physics_frames(2)
	assert_signal_emit_count(enemy, "died", 1)
	assert_false(hurtbox.monitorable)
	assert_false((enemy.get_node("ContactHitbox") as HitboxComponent).monitorable)


func test_hit_after_death_rejected() -> void:
	var enemy := _make_enemy()
	var hurtbox := enemy.get_node("HurtboxComponent") as HurtboxComponent
	hurtbox.receive_hit(1000.0, Vector2.ZERO)
	assert_false(hurtbox.receive_hit(1.0, Vector2.ZERO))


func test_contact_damages_player_integration() -> void:
	var player := load("res://scenes/player/player.tscn").instantiate() as Player
	add_child_autofree(player)
	var enemy := _make_enemy()
	enemy.global_position = player.global_position
	await wait_physics_frames(4)
	var expected := player.health.max_health - _data().contact_damage
	assert_eq(player.health.current_health, expected)
	await wait_physics_frames(4)
	assert_eq(player.health.current_health, expected)


func test_contact_cooldown_outlasts_player_invulnerability() -> void:
	var player := load("res://scenes/player/player.tscn").instantiate() as Player
	add_child_autofree(player)
	var hurtbox := player.get_node("HurtboxComponent") as HurtboxComponent
	var enemy := _make_enemy()
	var hitbox := enemy.get_node("ContactHitbox") as HitboxComponent
	assert_true(hitbox.try_hit(hurtbox, 0))
	hurtbox._process(player.get_node("HurtboxComponent").invulnerability_time + 0.1)
	assert_false(hitbox.try_hit(hurtbox, 600))
	assert_true(hitbox.try_hit(hurtbox, 1100))


func test_enemy_closes_in_until_it_touches_the_player() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.add_to_group(&"player")
	player.global_position = Vector2(200, 200)
	var enemy := _make_enemy()
	enemy.setup(_data(), Rect2(0, 0, 960, 540), _rng(3))
	enemy.target_offset = Vector2(_data().offset_radius, 0.0)
	enemy.global_position = Vector2(150, 200)
	for i in 400:
		enemy._physics_process(0.05)
	assert_lt(enemy.global_position.distance_to(player.global_position), 6.0, "enemy stopped short of the player")
