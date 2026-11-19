extends GutTest

var _player: Player


func before_each() -> void:
	_player = load("res://scenes/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)


func after_each() -> void:
	Input.action_release(&"move_right")


func _hurtbox() -> HurtboxComponent:
	return _player.get_node("HurtboxComponent") as HurtboxComponent


func test_hit_reduces_health_and_flashes_and_knocks_back() -> void:
	_hurtbox().receive_hit(10.0, Vector2(-10, 0), 100.0)
	assert_eq(_player.health.current_health, 90.0)
	assert_true((_player.get_node("HitFlashComponent") as HitFlashComponent).is_flashing)
	assert_gt((_player.get_node("KnockbackComponent") as KnockbackComponent).velocity.x, 0.0)


func test_second_hit_inside_window_ignored() -> void:
	_hurtbox().receive_hit(10.0, Vector2.ZERO)
	assert_false(_hurtbox().receive_hit(10.0, Vector2.ZERO))
	assert_eq(_player.health.current_health, 90.0)


func test_many_hits_same_frame_deal_damage_once() -> void:
	for i in 10:
		_hurtbox().receive_hit(10.0, Vector2.ZERO)
	assert_eq(_player.health.current_health, 90.0)


func test_death_emits_once_leaves_group_and_stops_movement() -> void:
	watch_signals(_player)
	_hurtbox().receive_hit(1000.0, Vector2.ZERO)
	_hurtbox().receive_hit(1000.0, Vector2.ZERO)
	assert_signal_emit_count(_player, "died", 1)
	assert_false(_player.is_in_group(&"player"))
	var start := _player.global_position
	Input.action_press(&"move_right")
	await wait_physics_frames(3)
	assert_eq(_player.global_position, start)


func test_knockback_moves_player_away_from_source() -> void:
	var start := _player.global_position
	_hurtbox().receive_hit(1.0, start + Vector2(-10, 0), 100.0)
	await wait_physics_frames(3)
	assert_gt(_player.global_position.x, start.x)
