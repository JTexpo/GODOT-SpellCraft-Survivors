extends GutTest


func _launch(direction: Vector2 = Vector2.RIGHT, at: Vector2 = Vector2.ZERO) -> Projectile:
	var data := load("res://resources/attacks/basic_attack.tres") as AttackData
	var projectile := data.projectile_scene.instantiate() as Projectile
	add_child_autofree(projectile)
	projectile.global_position = at
	projectile.launch(direction, data)
	return projectile


func test_projectile_moves_straight() -> void:
	var data := load("res://resources/attacks/basic_attack.tres") as AttackData
	var projectile := _launch()
	projectile._physics_process(0.1)
	assert_almost_eq(projectile.position.x, data.projectile_speed * 0.1, 0.01)
	assert_almost_eq(projectile.position.y, 0.0, 0.01)


func test_projectile_freed_after_lifetime() -> void:
	var data := load("res://resources/attacks/basic_attack.tres") as AttackData
	var projectile := _launch()
	projectile._physics_process(data.lifetime + 0.1)
	assert_true(projectile.is_queued_for_deletion())


func test_projectile_hits_one_enemy_and_frees_integration() -> void:
	var enemy_scene := load("res://scenes/enemies/base_enemy.tscn") as PackedScene
	var first := enemy_scene.instantiate() as Enemy
	var second := enemy_scene.instantiate() as Enemy
	add_child_autofree(first)
	add_child_autofree(second)
	first.global_position = Vector2(0, 0)
	second.global_position = Vector2(2, 0)
	var projectile := _launch(Vector2.RIGHT, Vector2(1, 0))
	await wait_physics_frames(6)
	var damaged := 0
	for enemy in [first, second]:
		var health := enemy.get_node("HealthComponent") as HealthComponent
		if health.current_health < health.max_health:
			damaged += 1
	assert_eq(damaged, 1)
	assert_false(is_instance_valid(projectile))


func test_alive_player_fires_and_dead_player_does_not() -> void:
	var player := load("res://scenes/player/player.tscn").instantiate() as Player
	add_child_autofree(player)
	Input.action_press(&"cast")
	await wait_physics_frames(4)
	var fired := _count_projectiles(player.get_parent())
	assert_gt(fired, 0, "alive player should fire while cast is held")
	(player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	for child in player.get_parent().get_children():
		if child is Projectile:
			child.queue_free()
	await wait_physics_frames(3)
	assert_eq(_count_projectiles(player.get_parent()), 0)
	Input.action_release(&"cast")


func _count_projectiles(parent: Node) -> int:
	var count := 0
	for child in parent.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			count += 1
	return count
