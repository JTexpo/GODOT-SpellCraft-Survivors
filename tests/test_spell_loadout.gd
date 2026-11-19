extends GutTest

const PATHS := [
	"res://resources/spells/fire.tres",
	"res://resources/spells/thunder.tres",
	"res://resources/spells/land.tres",
	"res://resources/spells/sea.tres",
]

var _root: Node2D
var _loadout: SpellLoadout


func _make_loadout(spells: Array[SpellData]) -> SpellLoadout:
	var loadout := SpellLoadout.new()
	loadout.starting_spells = spells
	loadout.projectile_root = _root
	add_child_autofree(loadout)
	return loadout


func _four_spells() -> Array[SpellData]:
	var spells: Array[SpellData] = []
	for path in PATHS:
		spells.append(load(path) as SpellData)
	spells.append(null)
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
	_loadout = _make_loadout(_four_spells())


func test_four_slots_filled_and_fifth_empty() -> void:
	assert_eq(_loadout.slots.size(), SpellLoadout.SLOT_COUNT)
	for i in 4:
		assert_not_null(_loadout.slots[i])
	assert_null(_loadout.slots[4])
	assert_eq(_loadout.selected_index, 0)


func test_select_changes_selection_and_emits() -> void:
	watch_signals(_loadout)
	assert_true(_loadout.select(2))
	assert_eq(_loadout.selected_index, 2)
	assert_signal_emitted_with_parameters(_loadout, "selection_changed", [2])


func test_select_rejects_empty_out_of_range_and_current() -> void:
	assert_false(_loadout.select(4))
	assert_false(_loadout.select(9))
	assert_false(_loadout.select(-1))
	assert_false(_loadout.select(0))
	assert_eq(_loadout.selected_index, 0)


func test_cycle_wraps_and_skips_empty_slots() -> void:
	_loadout.select(3)
	assert_true(_loadout.cycle(1))
	assert_eq(_loadout.selected_index, 0)
	assert_true(_loadout.cycle(-1))
	assert_eq(_loadout.selected_index, 3)


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
	_loadout.select(2)
	var land := _loadout.slots[2] as SpellInstance
	assert_true(_loadout.try_cast(Vector2(5, 5), Vector2.RIGHT))
	assert_eq(_projectile_count(), 1)
	var projectile := _root.get_child(_root.get_child_count() - 1) as MissileArea
	assert_eq(projectile.global_position, Vector2(5, 5))
	assert_eq(projectile.direction, Vector2.RIGHT)
	assert_eq(land.current_mana, land.data.max_mana - land.data.mana_cost)
	for i in [0, 1, 3]:
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
	for i in 4:
		var spell := _loadout.slots[i] as SpellInstance
		assert_eq(spell.current_mana, spell.data.max_mana)
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))


func test_two_loadouts_from_same_spells_do_not_share_mana() -> void:
	var other := _make_loadout(_four_spells())
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
