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


func _unlock_and_equip(index: int) -> void:
	while not _player.loadout.is_unlocked(index):
		_player.loadout.unlock_next()
	_player.loadout.equip(index, load("res://resources/spells/thunder_cone.tres") as SpellData)


func test_slot_keys_ignore_locked_slots_and_select_unlocked_ones() -> void:
	_player._unhandled_input(_action_event(&"spell_slot_2"))
	assert_eq(_player.loadout.selected_index, 0, "slot 2 is locked")
	_player._unhandled_input(_action_event(&"spell_slot_5"))
	assert_eq(_player.loadout.selected_index, 0, "slot 5 is locked")
	_unlock_and_equip(1)
	_player._unhandled_input(_action_event(&"spell_slot_2"))
	assert_eq(_player.loadout.selected_index, 1)


func test_shoulder_actions_cycle_spells() -> void:
	_unlock_and_equip(1)
	_player._unhandled_input(_action_event(&"spell_next"))
	assert_eq(_player.loadout.selected_index, 1)
	_player._unhandled_input(_action_event(&"spell_prev"))
	assert_eq(_player.loadout.selected_index, 0)


func test_shoulder_actions_do_nothing_with_one_spell() -> void:
	_player._unhandled_input(_action_event(&"spell_next"))
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


func test_player_exposes_its_aim_component() -> void:
	assert_true(_player.aim is AimComponent)
	assert_eq(_player.aim, _player.get_node("AimComponent"))


func test_player_starts_with_only_fire_missile_and_four_locked_slots() -> void:
	var loadout := _player.loadout
	assert_eq(loadout.slots[0].data.id, &"fire_missile")
	assert_eq(loadout.slots[0].data.max_mana, 100.0)
	assert_eq(loadout.slots[0].current_mana, 100.0)
	assert_eq(loadout.unlocked_slots, 1)
	for i in range(1, 5):
		assert_null(loadout.slots[i], "slot %d" % i)
		assert_false(loadout.is_unlocked(i), "slot %d" % i)


func test_player_has_a_scroll_inventory() -> void:
	assert_true(_player.inventory is ScrollInventory)
	assert_eq(_player.inventory, _player.get_node("ScrollInventory"))


func test_player_has_a_pickup_collector() -> void:
	assert_true(_player.collector is PickupCollector)
	assert_eq(_player.collector.inventory, _player.inventory)
	assert_eq(_player.collector.collision_mask, PhysicsLayers.PICKUP)


func test_no_cast_until_the_cast_input_is_released_after_resume() -> void:
	_player.require_cast_release()
	Input.action_press(&"cast")
	await wait_physics_frames(6)
	assert_eq(_projectile_count(), 0, "the held click must not fire")
	var fire := _player.loadout.slots[0] as SpellInstance
	assert_eq(fire.current_mana, fire.data.max_mana)
	Input.action_release(&"cast")
	await wait_physics_frames(3)
	Input.action_press(&"cast")
	await wait_physics_frames(4)
	Input.action_release(&"cast")
	assert_gt(_projectile_count(), 0, "after a release it casts again")
