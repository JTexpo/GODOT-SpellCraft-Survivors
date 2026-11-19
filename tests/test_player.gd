extends GutTest

var _root: Node2D
var _player: Player


func before_each() -> void:
	# Projectiles land in the player's parent, so give each test its own.
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = load("res://scenes/player/player.tscn").instantiate() as Player
	_root.add_child(_player)


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


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _projectile_count() -> int:
	var count := 0
	for child in _root.get_children():
		if child is MissileArea and not child.is_queued_for_deletion():
			count += 1
	return count


func test_alive_player_casts_and_spends_mana_from_the_selected_spell() -> void:
	Input.action_press(&"cast")
	await wait_physics_frames(4)
	Input.action_release(&"cast")
	assert_gt(_projectile_count(), 0)
	var fire := _player.loadout.slots[0] as SpellInstance
	assert_lt(fire.current_mana, fire.data.max_mana)


func test_slot_keys_select_spells_and_empty_slot_is_ignored() -> void:
	_player._unhandled_input(_action_event(&"spell_slot_2"))
	assert_eq(_player.loadout.selected_index, 1)
	_player._unhandled_input(_action_event(&"spell_slot_5"))
	assert_eq(_player.loadout.selected_index, 1)


func test_shoulder_actions_cycle_spells() -> void:
	_player._unhandled_input(_action_event(&"spell_next"))
	assert_eq(_player.loadout.selected_index, 1)
	_player._unhandled_input(_action_event(&"spell_prev"))
	assert_eq(_player.loadout.selected_index, 0)


func test_dead_player_ignores_slot_input_and_casts_nothing() -> void:
	_hurtbox().receive_hit(1000.0, Vector2.ZERO)
	_player._unhandled_input(_action_event(&"spell_slot_2"))
	assert_eq(_player.loadout.selected_index, 0)
	Input.action_press(&"cast")
	await wait_physics_frames(4)
	Input.action_release(&"cast")
	assert_eq(_projectile_count(), 0)


func test_depleted_spell_does_nothing_and_does_not_switch() -> void:
	_player.loadout.selected().current_mana = 0.0
	Input.action_press(&"cast")
	await wait_physics_frames(4)
	Input.action_release(&"cast")
	assert_eq(_projectile_count(), 0)
	assert_eq(_player.loadout.selected_index, 0)
