extends GutTest

const BOUNDS := Rect2(0, 0, 960, 540)
const VIEW := Vector2(480, 270)

var _player: Node2D
var _spawner: EnemySpawner


func before_each() -> void:
	_player = Node2D.new()
	add_child_autofree(_player)
	_player.add_to_group(&"player")
	_player.global_position = Vector2(480, 270)
	_spawner = _make_spawner(3)


func after_each() -> void:
	for child in get_children():
		if child is Enemy:
			child.free()


func _make_spawner(max_alive: int) -> EnemySpawner:
	var config := SpawnConfig.new()
	config.interval = 0.5
	config.max_alive = max_alive
	config.spawn_margin = 24.0
	config.enemy_scene = load("res://scenes/enemies/base_enemy.tscn")
	config.enemy_data = load("res://resources/enemies/basic_enemy.tres")
	var spawner := EnemySpawner.new()
	spawner.config = config
	spawner.arena_bounds = BOUNDS
	spawner.view_size = VIEW
	add_child_autofree(spawner)
	spawner.rng.seed = 7
	return spawner


func test_never_exceeds_max_alive() -> void:
	for i in 10:
		_spawner.try_spawn()
	assert_eq(_spawner.alive, 3)


func test_alive_decrements_on_enemy_death() -> void:
	var enemy := _spawner.try_spawn()
	assert_eq(_spawner.alive, 1)
	(enemy.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_eq(_spawner.alive, 0)


func _inside_inclusive(rect: Rect2, point: Vector2) -> bool:
	return point.x >= rect.position.x and point.y >= rect.position.y \
		and point.x <= rect.end.x and point.y <= rect.end.y


func test_spawn_position_inside_bounds_and_outside_view() -> void:
	var spots: Array[Vector2] = [
		Vector2(480, 270), Vector2(0, 0), Vector2(960, 0), Vector2(0, 540), Vector2(960, 540),
	]
	for spot in spots:
		var view_rect := Rect2(spot - VIEW / 2.0, VIEW)
		for seed_value in 200:
			_spawner.rng.seed = seed_value
			var position := _spawner.spawn_position(spot)
			if position == Vector2.INF:
				continue
			assert_true(_inside_inclusive(BOUNDS, position), "%s outside arena (player at %s)" % [position, spot])
			assert_false(view_rect.has_point(position), "%s inside view (player at %s)" % [position, spot])


func test_no_spawn_without_player() -> void:
	_player.remove_from_group(&"player")
	assert_null(_spawner.try_spawn())


func test_no_spawn_after_player_leaves_group_mid_run() -> void:
	assert_not_null(_spawner.try_spawn())
	_player.remove_from_group(&"player")
	_spawner.tick(5.0)
	assert_eq(_spawner.alive, 1)


func test_tick_respects_interval() -> void:
	_spawner.tick(0.4)
	assert_eq(_spawner.alive, 0)
	_spawner.tick(0.2)
	assert_eq(_spawner.alive, 1)
