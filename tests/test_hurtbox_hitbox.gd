extends GutTest


func _add_circle(area: Area2D, radius: float) -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	area.add_child(shape)


func _make_target(position: Vector2 = Vector2.ZERO, hp: float = 10.0, invulnerability: float = 0.0) -> HurtboxComponent:
	var holder := Node2D.new()
	holder.position = position
	var health := HealthComponent.new()
	health.max_health = hp
	holder.add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.health = health
	hurtbox.invulnerability_time = invulnerability
	hurtbox.collision_layer = PhysicsLayers.ENEMY_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	_add_circle(hurtbox, 6.0)
	holder.add_child(hurtbox)
	add_child_autofree(holder)
	return hurtbox


func _make_hitbox(damage: float = 10.0, cooldown: float = 0.0) -> HitboxComponent:
	var hitbox := HitboxComponent.new()
	hitbox.damage = damage
	hitbox.hit_cooldown = cooldown
	hitbox.monitoring = false
	add_child_autofree(hitbox)
	return hitbox


func test_receive_hit_damages_health_and_emits() -> void:
	var target := _make_target()
	watch_signals(target)
	assert_true(target.receive_hit(4.0, Vector2(-10, 0), 50.0))
	assert_eq(target.health.current_health, 6.0)
	assert_signal_emitted_with_parameters(target, "hit_received", [4.0, Vector2(-10, 0), 50.0])


func test_invulnerable_after_hit_rejects_second() -> void:
	var target := _make_target(Vector2.ZERO, 10.0, 0.5)
	assert_true(target.receive_hit(3.0, Vector2.ZERO))
	assert_true(target.is_invulnerable())
	assert_false(target.receive_hit(3.0, Vector2.ZERO))
	assert_eq(target.health.current_health, 7.0)


func test_invulnerability_expires() -> void:
	var target := _make_target(Vector2.ZERO, 10.0, 0.5)
	target.receive_hit(3.0, Vector2.ZERO)
	target._process(0.6)
	assert_false(target.is_invulnerable())
	assert_true(target.receive_hit(3.0, Vector2.ZERO))
	assert_eq(target.health.current_health, 4.0)


func test_hit_on_dead_target_rejected() -> void:
	var target := _make_target()
	assert_true(target.receive_hit(100.0, Vector2.ZERO))
	assert_false(target.receive_hit(1.0, Vector2.ZERO))


func test_cooldown_blocks_repeat_hits() -> void:
	var target := _make_target(Vector2.ZERO, 100.0)
	var hitbox := _make_hitbox(5.0, 1.0)
	assert_true(hitbox.try_hit(target, 0))
	assert_false(hitbox.try_hit(target, 500))
	assert_true(hitbox.try_hit(target, 1100))
	assert_eq(target.health.current_health, 90.0)


func test_rejected_hit_does_not_consume_cooldown() -> void:
	var target := _make_target(Vector2.ZERO, 100.0, 0.5)
	target.receive_hit(1.0, Vector2.ZERO)
	var hitbox := _make_hitbox(5.0, 1.0)
	assert_false(hitbox.try_hit(target, 0))
	target._process(0.6)
	assert_true(hitbox.try_hit(target, 10))


func test_one_shot_hits_only_one_of_two_overlapping() -> void:
	var near := _make_target(Vector2(5, 0))
	var also_near := _make_target(Vector2(-5, 0))
	var hitbox := HitboxComponent.new()
	hitbox.damage = 4.0
	hitbox.one_shot = true
	hitbox.collision_layer = PhysicsLayers.PLAYER_PROJECTILE
	hitbox.collision_mask = PhysicsLayers.ENEMY_HURTBOX
	hitbox.monitoring = true
	_add_circle(hitbox, 20.0)
	add_child_autofree(hitbox)
	await wait_physics_frames(4)
	var damaged := 0
	for target in [near, also_near]:
		if target.health.current_health < 10.0:
			damaged += 1
	assert_eq(damaged, 1)
	assert_false(hitbox.monitoring)
