extends GutTest

const PATHS := [
	"res://resources/spells/fire_missile.tres",
	"res://resources/spells/thunder_cone.tres",
	"res://resources/spells/land_area.tres",
	"res://resources/spells/sea_line.tres",
	"res://resources/spells/sea_wave.tres",
]

var _root: Node2D
var _loadout: SpellLoadout


func _make_loadout(spells: Array[SpellData]) -> SpellLoadout:
	var loadout := SpellLoadout.new()
	loadout.starting_spells = spells
	loadout.projectile_root = _root
	add_child_autofree(loadout)
	return loadout


func _five_spells() -> Array[SpellData]:
	var spells: Array[SpellData] = []
	for path in PATHS:
		spells.append(load(path) as SpellData)
	return spells


func _projectile_count() -> int:
	var count := 0
	for child in _root.get_children():
		if child is MissileArea:
			count += 1
	return count


func _drain_selected() -> void:
	var spell := _loadout.selected()
	spell.current_mana = 0.0


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_loadout = _make_loadout(_five_spells())


func _sparse_loadout() -> SpellLoadout:
	var spells: Array[SpellData] = [load(PATHS[0]) as SpellData, null, load(PATHS[2]) as SpellData, null, null]
	return _make_loadout(spells)


func test_five_slots_filled() -> void:
	assert_eq(_loadout.slots.size(), SpellLoadout.SLOT_COUNT)
	for i in 5:
		assert_not_null(_loadout.slots[i])
	assert_eq(_loadout.selected_index, 0)


func test_select_changes_selection_and_emits() -> void:
	watch_signals(_loadout)
	assert_true(_loadout.select(2))
	assert_eq(_loadout.selected_index, 2)
	assert_signal_emitted_with_parameters(_loadout, "selection_changed", [2])


func test_select_rejects_empty_out_of_range_and_current() -> void:
	var sparse := _sparse_loadout()
	assert_false(sparse.select(1))
	assert_false(_loadout.select(5))
	assert_false(_loadout.select(9))
	assert_false(_loadout.select(-1))
	assert_false(_loadout.select(0))
	assert_eq(sparse.selected_index, 0)
	assert_eq(_loadout.selected_index, 0)


func test_cycle_wraps_around_the_five_slots() -> void:
	_loadout.select(4)
	assert_true(_loadout.cycle(1))
	assert_eq(_loadout.selected_index, 0)
	assert_true(_loadout.cycle(-1))
	assert_eq(_loadout.selected_index, 4)


func test_cycle_skips_empty_slots() -> void:
	var sparse := _sparse_loadout()
	assert_true(sparse.cycle(1))
	assert_eq(sparse.selected_index, 2)
	assert_true(sparse.cycle(1))
	assert_eq(sparse.selected_index, 0)


func test_cycle_with_one_filled_slot_does_nothing() -> void:
	var spells: Array[SpellData] = [load(PATHS[0]) as SpellData, null, null, null, null]
	var lone := _make_loadout(spells)
	assert_false(lone.cycle(1))
	assert_false(lone.cycle(-1))
	assert_eq(lone.selected_index, 0)


func test_cycle_with_no_filled_slots_does_not_error() -> void:
	var spells: Array[SpellData] = [null, null, null, null, null]
	var empty := _make_loadout(spells)
	assert_false(empty.cycle(1))
	assert_null(empty.selected())


func test_cast_spawns_projectile_and_spends_only_selected_slot() -> void:
	var fire := _loadout.slots[0] as SpellInstance
	assert_true(_loadout.try_cast(Vector2(5, 5), Vector2.RIGHT))
	assert_eq(_projectile_count(), 1)
	var projectile := _root.get_child(_root.get_child_count() - 1) as MissileArea
	assert_eq(projectile.global_position, Vector2(5, 5))
	assert_eq(projectile.direction, Vector2.RIGHT)
	assert_eq(fire.current_mana, fire.data.max_mana - fire.data.mana_cost)
	for i in [1, 2, 3, 4]:
		var other := _loadout.slots[i] as SpellInstance
		assert_eq(other.current_mana, other.data.max_mana)


func test_cooldown_blocks_then_allows_cast() -> void:
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	assert_false(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	_loadout._process(_loadout.selected().data.cast_interval)
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	assert_eq(_projectile_count(), 2)


func test_zero_direction_casts_nothing() -> void:
	assert_false(_loadout.try_cast(Vector2.ZERO, Vector2.ZERO))
	assert_eq(_projectile_count(), 0)
	assert_eq(_loadout.selected().current_mana, _loadout.selected().data.max_mana)


func test_depleted_spell_never_fires_never_switches_and_cues_once() -> void:
	_drain_selected()
	watch_signals(_loadout)
	for i in 10:
		assert_false(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
		_loadout._process(1.0)
	assert_eq(_projectile_count(), 0)
	assert_eq(_loadout.selected().current_mana, 0.0)
	assert_eq(_loadout.selected_index, 0)
	assert_signal_emit_count(_loadout, "cast_failed_dry", 1)


func test_dry_cue_returns_after_end_cast_or_selection_change() -> void:
	_drain_selected()
	watch_signals(_loadout)
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	_loadout.end_cast()
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_signal_emit_count(_loadout, "cast_failed_dry", 2)
	_loadout.select(1)
	_drain_selected()
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_signal_emit_count(_loadout, "cast_failed_dry", 3)


func test_casting_on_empty_selection_does_nothing() -> void:
	var spells: Array[SpellData] = [null, load(PATHS[0]) as SpellData, null, null, null]
	var loadout := _make_loadout(spells)
	watch_signals(loadout)
	assert_false(loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	assert_signal_not_emitted(loadout, "cast_failed_dry")
	assert_eq(_projectile_count(), 0)


func test_restore_all_mana_refills_and_lets_depleted_spell_cast() -> void:
	_drain_selected()
	assert_false(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	_loadout.restore_all_mana()
	for i in 5:
		var spell := _loadout.slots[i] as SpellInstance
		assert_eq(spell.current_mana, spell.data.max_mana)
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))


func test_two_loadouts_from_same_spells_do_not_share_mana() -> void:
	var other := _make_loadout(_five_spells())
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	var mine := _loadout.slots[0] as SpellInstance
	var theirs := other.slots[0] as SpellInstance
	assert_lt(mine.current_mana, mine.data.max_mana)
	assert_eq(theirs.current_mana, theirs.data.max_mana)


func _stub_spell() -> SpellData:
	var node := StubAreaEffect.new()
	var scene := PackedScene.new()
	scene.pack(node)
	node.free()
	var area := AreaData.new()
	area.scene = scene
	var spell := SpellData.new()
	spell.area_data = area
	return spell


func _stub_loadout() -> SpellLoadout:
	var spells: Array[SpellData] = [_stub_spell(), null, null, null, null]
	return _make_loadout(spells)


func test_try_cast_launches_the_spells_own_area_scene() -> void:
	var loadout := _stub_loadout()
	assert_true(loadout.try_cast(Vector2(5, 5), Vector2.RIGHT, Vector2(50, 5)))
	var stub := _root.get_child(_root.get_child_count() - 1) as StubAreaEffect
	assert_not_null(stub)
	assert_eq(stub.launched_spell, loadout.selected().data)
	assert_eq(stub.launched_origin, Vector2(5, 5))
	assert_eq(stub.launched_direction, Vector2.RIGHT)
	assert_eq(stub.launched_target, Vector2(50, 5))


func test_non_finite_target_becomes_a_far_point_along_direction() -> void:
	var loadout := _stub_loadout()
	loadout.try_cast(Vector2(5, 5), Vector2.RIGHT)
	var stub := _root.get_child(_root.get_child_count() - 1) as StubAreaEffect
	assert_eq(stub.launched_target, Vector2(5, 5) + Vector2.RIGHT * 10000.0)


func test_spell_without_area_casts_nothing_and_spends_nothing() -> void:
	var spells: Array[SpellData] = [SpellData.new(), null, null, null, null]
	var loadout := _make_loadout(spells)
	var before := _root.get_child_count()
	assert_false(loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	assert_eq(_root.get_child_count(), before)
	assert_eq(loadout.selected().current_mana, loadout.selected().data.max_mana)


func test_depleted_area_spell_spawns_nothing_for_every_slot() -> void:
	for index in [1, 2, 3, 4]:
		_loadout.select(index)
		_drain_selected()
		var before := _root.get_child_count()
		assert_false(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT), "slot %d" % index)
		assert_eq(_root.get_child_count(), before, "slot %d" % index)
		assert_eq(_loadout.selected().current_mana, 0.0, "slot %d" % index)
		assert_eq(_loadout.selected_index, index)


func _make_limited(unlocked: int, spells: Array[SpellData]) -> SpellLoadout:
	var loadout := SpellLoadout.new()
	loadout.starting_spells = spells
	loadout.unlocked_slots = unlocked
	loadout.projectile_root = _root
	add_child_autofree(loadout)
	return loadout


func _spell(index: int) -> SpellData:
	return load(PATHS[index]) as SpellData


func test_locked_slots_hold_no_spell_even_if_listed() -> void:
	var limited := _make_limited(1, _five_spells())
	assert_not_null(limited.slots[0])
	for i in range(1, 5):
		assert_null(limited.slots[i], "slot %d" % i)
		assert_false(limited.is_unlocked(i))
	assert_true(limited.is_unlocked(0))
	assert_false(limited.is_unlocked(-1))
	assert_false(limited.is_unlocked(5))


func test_unlock_next_unlocks_one_slot_and_emits() -> void:
	var limited := _make_limited(1, _five_spells())
	watch_signals(limited)
	assert_true(limited.unlock_next())
	assert_true(limited.is_unlocked(1))
	assert_false(limited.is_unlocked(2))
	assert_signal_emitted_with_parameters(limited, "slot_unlocked", [1])
	for i in 3:
		assert_true(limited.unlock_next())
	assert_false(limited.unlock_next())
	assert_eq(limited.unlocked_slots, 5)
	assert_signal_emit_count(limited, "slot_unlocked", 4)


func test_equip_into_an_empty_unlocked_slot() -> void:
	var limited := _make_limited(2, [_spell(0)] as Array[SpellData])
	watch_signals(limited)
	var instance := limited.equip(1, _spell(1))
	assert_not_null(instance)
	assert_eq(limited.slots[1], instance)
	assert_eq(instance.current_mana, instance.data.max_mana)
	assert_signal_emitted_with_parameters(limited, "slot_changed", [1])


func test_equip_replaces_with_a_fresh_full_pool() -> void:
	var old := _loadout.slots[0] as SpellInstance
	old.current_mana = 1.0
	watch_signals(_loadout)
	var fresh := _loadout.equip(0, _spell(3))
	assert_ne(fresh, old)
	assert_eq(_loadout.slots[0], fresh)
	assert_eq(fresh.data, _spell(3))
	assert_eq(fresh.current_mana, fresh.data.max_mana)
	assert_eq(old.current_mana, 1.0, "the old instance is left alone")
	assert_signal_emitted_with_parameters(_loadout, "slot_changed", [0])


func test_equip_refuses_locked_out_of_range_and_null() -> void:
	var limited := _make_limited(1, [_spell(0)] as Array[SpellData])
	var before := limited.slots.duplicate()
	watch_signals(limited)
	assert_null(limited.equip(1, _spell(1)), "locked")
	assert_null(limited.equip(9, _spell(1)), "out of range")
	assert_null(limited.equip(-1, _spell(1)), "negative")
	assert_null(limited.equip(0, null), "no spell")
	assert_eq(limited.slots, before)
	assert_signal_not_emitted(limited, "slot_changed")


func test_select_and_cycle_skip_locked_slots() -> void:
	var limited := _make_limited(2, _five_spells())
	assert_false(limited.select(3))
	assert_true(limited.cycle(1))
	assert_eq(limited.selected_index, 1)
	assert_true(limited.cycle(1))
	assert_eq(limited.selected_index, 0)


func test_selection_survives_replacing_the_selected_slot() -> void:
	_loadout.select(2)
	_loadout.selected().current_mana = 0.0
	watch_signals(_loadout)
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_signal_emit_count(_loadout, "cast_failed_dry", 1)
	_loadout.equip(2, _spell(0))
	assert_eq(_loadout.selected_index, 2)
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT), "the new spell casts")
	_loadout.selected().current_mana = 0.0
	_loadout._process(10.0)
	_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_signal_emit_count(_loadout, "cast_failed_dry", 2)


func _stub_effects() -> Array[StubAreaEffect]:
	var found: Array[StubAreaEffect] = []
	for child in _root.get_children():
		if child is StubAreaEffect:
			found.append(child)
	return found


func _copies_loadout(copies: int) -> SpellLoadout:
	var spell := _stub_spell()
	spell.copies = copies
	var spells: Array[SpellData] = [spell, null, null, null, null]
	return _make_loadout(spells)


func test_a_three_copy_spell_launches_three_effects_with_ring_directions() -> void:
	var loadout := _copies_loadout(3)
	assert_true(loadout.try_cast(Vector2(5, 5), Vector2.RIGHT, Vector2(50, 5)))
	var stubs := _stub_effects()
	assert_eq(stubs.size(), 3)
	for i in 3:
		assert_almost_eq(absf(angle_difference(stubs[i].launched_direction.angle(), deg_to_rad(120.0 * i))), 0.0, 0.0001)
		assert_eq(stubs[i].launched_origin, Vector2(5, 5))
		assert_eq(stubs[i].launched_spell, loadout.selected().data)


func test_mana_is_spent_once_for_all_copies() -> void:
	var loadout := _copies_loadout(5)
	var spell := loadout.selected()
	loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_eq(_stub_effects().size(), 5)
	assert_eq(spell.current_mana, spell.data.max_mana - spell.data.mana_cost)


func test_a_one_copy_spell_launches_exactly_one_effect() -> void:
	var loadout := _copies_loadout(1)
	loadout.try_cast(Vector2.ZERO, Vector2.RIGHT)
	assert_eq(_stub_effects().size(), 1)


func test_mana_bonus_applies_to_existing_and_new_spells() -> void:
	var spells := _five_spells()
	var loadout := _make_loadout(spells)
	var first_pool := spells[0].max_mana
	loadout.set_mana_bonus(0.15)
	assert_almost_eq(loadout.slots[0].max_mana(), first_pool * 1.15, 0.0001)
	assert_almost_eq(loadout.slots[0].current_mana, first_pool * 1.15, 0.0001)
	var crafted := SpellData.new()
	crafted.max_mana = 100.0
	crafted.mana_cost = 1.0
	var instance := loadout.equip(1, crafted)
	assert_almost_eq(instance.max_mana(), 115.0, 0.0001)
	assert_almost_eq(instance.current_mana, 115.0, 0.0001)


func test_two_loadouts_never_share_a_bonus() -> void:
	var data := load("res://resources/spells/fire_missile.tres") as SpellData
	var first := _make_loadout([data] as Array[SpellData])
	var second := _make_loadout([data] as Array[SpellData])
	first.set_mana_bonus(0.3)
	assert_almost_eq(first.slots[0].max_mana(), data.max_mana * 1.3, 0.0001)
	assert_eq(second.slots[0].max_mana(), data.max_mana)
	assert_eq(data.max_mana, 1000.0)
