extends GutTest

var _rules: CraftingRules
var _inventory: ScrollInventory
var _loadout: SpellLoadout
var _root: Node2D
var _fire: ScrollData
var _thunder: ScrollData
var _missile: ScrollData
var _wave: ScrollData


func _scroll(path: String) -> ScrollData:
	return load("res://resources/scrolls/%s.tres" % path) as ScrollData


func _make_loadout(unlocked: int) -> SpellLoadout:
	var spells: Array[SpellData] = [load("res://resources/spells/fire_missile.tres") as SpellData]
	var loadout := SpellLoadout.new()
	loadout.starting_spells = spells
	loadout.unlocked_slots = unlocked
	loadout.projectile_root = _root
	add_child_autofree(loadout)
	return loadout


func _session() -> CraftingSession:
	return CraftingSession.new(_rules, _inventory, _loadout)


func before_each() -> void:
	_rules = CraftingRules.default_rules()
	_root = Node2D.new()
	add_child_autofree(_root)
	_inventory = ScrollInventory.new()
	add_child_autofree(_inventory)
	_loadout = _make_loadout(1)
	_fire = _scroll("base/fire")
	_thunder = _scroll("base/thunder")
	_missile = _scroll("area/missile")
	_wave = _scroll("area/wave")


func test_defaults() -> void:
	var session := _session()
	assert_eq(session.option_index, _rules.normal_index())
	assert_eq(session.slot_index, 0)
	assert_null(session.base)
	assert_null(session.area)
	assert_false(session.can_confirm())
	assert_eq(session.message(), CraftingSystem.REASON_NO_BASE)


func test_default_slot_is_the_selected_one_when_unlocked() -> void:
	_loadout = _make_loadout(3)
	_loadout.equip(2, load("res://resources/spells/thunder_cone.tres") as SpellData)
	_loadout.select(2)
	assert_eq(_session().slot_index, 2)


func test_empty_inventory_still_works() -> void:
	var session := _session()
	assert_eq(session.owned_bases(), [])
	assert_eq(session.owned_areas(), [])
	assert_eq(session.owned_buffs(), [])
	assert_null(session.preview())
	assert_eq(session.new_stats(), {})
	assert_false(session.message().is_empty())
	assert_false(session.confirm().ok)


func test_selecting_rules() -> void:
	_inventory.add(_fire)
	_inventory.add(_missile)
	var session := _session()
	watch_signals(session)
	assert_false(session.select_base(null))
	assert_false(session.select_base(_thunder), "not owned")
	assert_false(session.select_base(_missile), "wrong category")
	assert_false(session.select_area(_wave), "not owned")
	assert_false(session.select_area(_fire), "wrong category")
	assert_signal_not_emitted(session, "changed")
	assert_true(session.select_base(_fire))
	assert_eq(session.base, _fire)
	assert_true(session.select_base(_fire), "choosing it again clears it")
	assert_null(session.base)
	assert_true(session.select_area(_missile))
	assert_eq(session.area, _missile)
	assert_signal_emit_count(session, "changed", 3)


func test_select_range_and_slot_reject_bad_values() -> void:
	var session := _session()
	assert_false(session.select_range(-1))
	assert_false(session.select_range(9))
	assert_eq(session.option_index, _rules.normal_index())
	assert_true(session.select_range(2))
	assert_eq(session.option_index, 2)
	assert_false(session.select_slot(1), "locked")
	assert_false(session.select_slot(9))
	assert_false(session.select_slot(-1))
	assert_true(session.select_slot(0))


func test_preview_follows_the_choices() -> void:
	_inventory.add(_thunder)
	_inventory.add(_wave)
	var session := _session()
	session.select_base(_thunder)
	session.select_area(_wave)
	session.select_range(2)
	var built := SpellBuilder.build(_thunder, _wave, _rules.option(2))
	var preview := session.preview()
	assert_not_null(preview)
	assert_eq(preview.mana_cost, built.mana_cost)
	assert_eq(preview.max_mana, built.max_mana)
	assert_eq(preview.range_scale, built.range_scale)
	assert_eq(session.new_stats(), SpellBuilder.describe(built))
	assert_true(session.can_confirm())
	assert_eq(session.message(), "")


func test_current_stats_show_the_target_slot() -> void:
	var session := _session()
	assert_eq(session.current_stats()["name"], "Fire Missile")
	_loadout = _make_loadout(2)
	var other := _session()
	other.select_slot(1)
	assert_eq(other.current_stats(), {})


func test_replace_note_variants() -> void:
	var session := _session()
	assert_eq(session.replace_note(), "Replaces Fire Missile (1000 / 1000 mana left)")
	_loadout.slots[0].current_mana = 12.0
	assert_eq(session.replace_note(), "Replaces Fire Missile (12 / 1000 mana left)")
	_loadout.slots[0].current_mana = 0.0
	assert_eq(session.replace_note(), "Replaces Fire Missile (empty)")
	_loadout = _make_loadout(2)
	var other := _session()
	other.select_slot(1)
	assert_eq(other.replace_note(), "Empty slot")


func test_confirm_crafts_and_clears_spent_choices() -> void:
	_inventory.add(_fire)
	_inventory.add(_missile, 2)
	var session := _session()
	session.select_base(_fire)
	session.select_area(_missile)
	var result := session.confirm()
	assert_true(result.ok)
	assert_eq(_loadout.slots[0].data, result.spell)
	assert_null(session.base, "the last Fire scroll was used up")
	assert_eq(session.area, _missile, "one Missile scroll is left")
	assert_eq(_inventory.count(_missile), 1)


func test_confirm_when_invalid_changes_nothing() -> void:
	_inventory.add(_fire)
	var session := _session()
	session.select_base(_fire)
	var before_slot := _loadout.slots[0]
	var result := session.confirm()
	assert_false(result.ok)
	assert_eq(result.reason, CraftingSystem.REASON_NO_AREA)
	assert_eq(_inventory.count(_fire), 1)
	assert_eq(_loadout.slots[0], before_slot)


func test_owned_buffs_are_listed_but_never_craftable() -> void:
	var buff := _scroll("buff/damage")
	_inventory.add(buff)
	_inventory.add(_fire)
	_inventory.add(_missile)
	var session := _session()
	assert_eq(session.owned_buffs(), [buff])
	assert_false(session.select_base(buff))
	assert_false(session.select_area(buff))
	session.select_base(_fire)
	session.select_area(_missile)
	assert_eq(session.request().buffs, [])
	assert_true(session.confirm().ok)
	assert_eq(_inventory.count(buff), 1, "the buff scroll is untouched")
