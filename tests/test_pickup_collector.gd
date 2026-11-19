extends GutTest

const PICKUP_SCENE := "res://scenes/scrolls/scroll_pickup.tscn"

var _root: Node2D
var _player: Player
var _fire: ScrollData


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = load("res://scenes/player/player.tscn").instantiate() as Player
	_root.add_child(_player)
	_player.global_position = Vector2(100, 100)
	_fire = load("res://resources/scrolls/base/fire.tres") as ScrollData


func _drop(at: Vector2) -> ScrollPickup:
	var pickup := (load(PICKUP_SCENE) as PackedScene).instantiate() as ScrollPickup
	_root.add_child(pickup)
	pickup.setup(_fire)
	pickup.global_position = at
	return pickup


func test_walking_over_a_pickup_collects_it() -> void:
	watch_signals(_player.collector)
	var pickup := _drop(_player.global_position)
	await wait_physics_frames(4)
	assert_eq(_player.inventory.count(_fire), 1)
	assert_signal_emit_count(_player.collector, "collected", 1)
	assert_signal_emitted_with_parameters(_player.collector, "collected", [_fire])
	assert_true(not is_instance_valid(pickup) or pickup.is_queued_for_deletion())


func test_pickups_outside_the_radius_are_left_alone() -> void:
	var pickup := _drop(_player.global_position + Vector2(60, 0))
	await wait_physics_frames(4)
	assert_eq(_player.inventory.count(_fire), 0)
	assert_false(pickup.is_queued_for_deletion())


func test_several_pickups_in_one_frame_are_each_collected_once() -> void:
	watch_signals(_player.collector)
	for i in 5:
		_drop(_player.global_position)
	await wait_physics_frames(4)
	assert_eq(_player.inventory.count(_fire), 5)
	assert_signal_emit_count(_player.collector, "collected", 5)


func test_a_pickup_is_never_collected_twice() -> void:
	_drop(_player.global_position)
	await wait_physics_frames(14)
	assert_eq(_player.inventory.count(_fire), 1)


func test_dead_player_collects_nothing() -> void:
	(_player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	var pickup := _drop(_player.global_position)
	await wait_physics_frames(6)
	assert_eq(_player.inventory.total_count(), 0)
	assert_false(pickup.is_queued_for_deletion())
