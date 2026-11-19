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
	config.enemy_pool = [load("res://resources/enemies/basic_enemy.tres") as EnemyData]
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


func test_spawn_position_inside_bounds_and_outside_the_camera_view() -> void:
	var spots: Array[Vector2] = [
		Vector2(480, 270), Vector2(0, 0), Vector2(960, 0), Vector2(0, 540), Vector2(960, 540),
		Vector2(200, 270), Vector2(480, 30), Vector2(940, 520), Vector2(100, 100),
	]
	for spot in spots:
		# The camera stops scrolling at the arena edge, so the visible area is the player-centred view
		# pushed back inside the arena.
		var view_center := spot.clamp(BOUNDS.position + VIEW / 2.0, BOUNDS.end - VIEW / 2.0)
		var view_rect := Rect2(view_center - VIEW / 2.0, VIEW)
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


const POOL_FILES := [
	"res://resources/enemies/basic_enemy.tres",
	"res://resources/enemies/fire_enemy.tres",
	"res://resources/enemies/thunder_enemy.tres",
	"res://resources/enemies/land_enemy.tres",
	"res://resources/enemies/sea_enemy.tres",
]


func _set_pool(pool: Array[EnemyData]) -> void:
	_spawner.config.enemy_pool = pool


func _file_pool() -> Array[EnemyData]:
	var pool: Array[EnemyData] = []
	for path in POOL_FILES:
		pool.append(load(path) as EnemyData)
	return pool


func test_pick_covers_every_pool_entry() -> void:
	var pool := _file_pool()
	_set_pool(pool)
	var seen := {}
	for i in 500:
		seen[_spawner.pick_enemy_data()] = true
	assert_eq(seen.size(), 5)
	for data in pool:
		assert_true(seen.has(data))


func test_pick_respects_weights() -> void:
	var light := (load(POOL_FILES[0]) as EnemyData).duplicate() as EnemyData
	var heavy := (load(POOL_FILES[0]) as EnemyData).duplicate() as EnemyData
	light.spawn_weight = 1.0
	heavy.spawn_weight = 3.0
	var pool: Array[EnemyData] = [light, heavy]
	_set_pool(pool)
	var counts := {light: 0, heavy: 0}
	for i in 1000:
		counts[_spawner.pick_enemy_data()] += 1
	assert_gt(counts[heavy], counts[light] * 2)


func test_single_entry_pool_always_picks_it() -> void:
	for i in 20:
		assert_eq(_spawner.pick_enemy_data(), _spawner.config.enemy_pool[0])


func test_empty_pool_and_zero_weights_spawn_nothing() -> void:
	var empty: Array[EnemyData] = []
	_set_pool(empty)
	assert_null(_spawner.pick_enemy_data())
	assert_null(_spawner.try_spawn())
	var dead := (load(POOL_FILES[0]) as EnemyData).duplicate() as EnemyData
	dead.spawn_weight = 0.0
	var zero: Array[EnemyData] = [dead, dead]
	_set_pool(zero)
	assert_null(_spawner.pick_enemy_data())
	assert_null(_spawner.try_spawn())
	assert_eq(_spawner.alive, 0)


func test_spawned_enemy_uses_data_from_the_pool() -> void:
	var pool := _file_pool()
	_set_pool(pool)
	_spawner.config.max_alive = 20
	for i in 10:
		var enemy := _spawner.try_spawn()
		assert_true(pool.has(enemy.data))


func test_enemy_damaged_is_re_emitted() -> void:
	var enemy := _spawner.try_spawn()
	watch_signals(_spawner)
	watch_signals(enemy)
	(enemy.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(10.0, Vector2.ZERO, 0.0, SpellData.Element.FIRE)
	assert_signal_emit_count(_spawner, "enemy_damaged", 1)
	assert_signal_emit_count(enemy, "damaged", 1)
	var params = get_signal_parameters(enemy, "damaged")
	assert_signal_emitted_with_parameters(_spawner, "enemy_damaged", params)
