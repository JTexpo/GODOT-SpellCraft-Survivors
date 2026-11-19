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
	var spells: Array[SpellData] = [
		load("res://resources/spells/fire_missile.tres") as SpellData,
		load("res://resources/spells/thunder_cone.tres") as SpellData,
		load("res://resources/spells/land_area.tres") as SpellData,
	]
	var loadout := SpellLoadout.new()
	loadout.starting_spells = spells
	loadout.unlocked_slots = unlocked
	loadout.projectile_root = _root
	add_child_autofree(loadout)
	return loadout


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


func _request(base: ScrollData, area: ScrollData, option_index: int = 1, slot: int = 0) -> CraftingRequest:
	var request := CraftingRequest.new()
	request.base = base
	request.area = area
	request.option_index = option_index
	request.slot_index = slot
	return request


func _snapshot() -> Dictionary:
	var slots := []
	for slot in _loadout.slots:
		slots.append([slot, slot.current_mana if slot != null else -1.0])
	var counts := []
	for scroll in [_fire, _thunder, _missile, _wave]:
		counts.append(_inventory.count(scroll))
	return {"slots": slots, "counts": counts, "total": _inventory.total_count()}


func test_valid_craft_consumes_exactly_one_of_each_and_equips() -> void:
	_inventory.add(_fire, 2)
	_inventory.add(_missile)
	var result := CraftingSystem.craft(_request(_fire, _missile), _rules, _inventory, _loadout)
	assert_true(result.ok)
	assert_eq(result.reason, "")
	assert_eq(_inventory.count(_fire), 1)
	assert_eq(_inventory.count(_missile), 0)
	var crafted := _loadout.slots[0] as SpellInstance
	assert_eq(crafted.data, result.spell)
	assert_eq(crafted.data.id, &"fire_missile_normal")
	assert_eq(crafted.current_mana, crafted.data.max_mana)


func test_craft_replaces_the_target_slot_only() -> void:
	_loadout = _make_loadout(3)
	_inventory.add(_thunder)
	_inventory.add(_wave)
	var before_0 := _loadout.slots[0]
	var before_1 := _loadout.slots[1]
	var result := CraftingSystem.craft(_request(_thunder, _wave, 2, 2), _rules, _inventory, _loadout)
	assert_true(result.ok)
	assert_eq(_loadout.slots[0], before_0)
	assert_eq(_loadout.slots[1], before_1)
	assert_eq(_loadout.slots[2].data.display_name, "Thunder Wave (Long)")


func test_each_invalid_case_changes_nothing() -> void:
	_inventory.add(_fire)
	_inventory.add(_missile)
	var area_scroll := _missile
	var cases := [
		["no base", _request(null, _missile), CraftingSystem.REASON_NO_BASE],
		["no area", _request(_fire, null), CraftingSystem.REASON_NO_AREA],
		["area as base", _request(_missile, _missile), CraftingSystem.REASON_WRONG_BASE],
		["base as area", _request(_fire, _fire), CraftingSystem.REASON_WRONG_AREA],
		["range -1", _request(_fire, _missile, -1), CraftingSystem.REASON_BAD_RANGE],
		["range 9", _request(_fire, _missile, 9), CraftingSystem.REASON_BAD_RANGE],
		["locked slot", _request(_fire, _missile, 1, 1), CraftingSystem.REASON_LOCKED_SLOT],
		["slot out of range", _request(_fire, _missile, 1, 9), CraftingSystem.REASON_LOCKED_SLOT],
		["negative slot", _request(_fire, _missile, 1, -1), CraftingSystem.REASON_LOCKED_SLOT],
		["base not owned", _request(_thunder, _missile), CraftingSystem.REASON_MISSING],
		["area not owned", _request(_fire, _wave), CraftingSystem.REASON_MISSING],
	]
	var buffed := _request(_fire, _missile)
	buffed.buffs = [_scroll("buff/damage")] as Array[ScrollData]
	cases.append(["buffs given", buffed, CraftingSystem.REASON_BUFFS_LOCKED])
	watch_signals(_inventory)
	watch_signals(_loadout)
	for case in cases:
		var before := _snapshot()
		var result := CraftingSystem.craft(case[1], _rules, _inventory, _loadout)
		assert_false(result.ok, case[0])
		assert_eq(result.reason, case[2], case[0])
		assert_eq(_snapshot(), before, "%s changed something" % case[0])
	assert_signal_not_emitted(_inventory, "changed")
	assert_signal_not_emitted(_loadout, "slot_changed")
	assert_not_null(area_scroll)


func test_preview_ignores_the_inventory_and_slot() -> void:
	var spell := CraftingSystem.preview(_request(_fire, _missile, 1, 9), _rules)
	assert_not_null(spell)
	assert_eq(spell.display_name, "Fire Missile")
	assert_null(CraftingSystem.preview(_request(null, _missile), _rules))
	assert_null(CraftingSystem.preview(_request(_fire, _missile, 9), _rules))


func test_validate_never_consumes_and_carries_the_spell() -> void:
	_inventory.add(_fire)
	_inventory.add(_missile)
	var before := _snapshot()
	for i in 3:
		var result := CraftingSystem.validate(_request(_fire, _missile), _rules, _inventory, _loadout)
		assert_true(result.ok)
		assert_not_null(result.spell)
	assert_eq(_snapshot(), before)
	var missing := CraftingSystem.validate(_request(_thunder, _missile), _rules, _inventory, _loadout)
	assert_false(missing.ok)
	assert_not_null(missing.spell, "the preview spell is still carried for the screen")


func test_a_second_craft_needs_new_scrolls() -> void:
	_inventory.add(_fire)
	_inventory.add(_missile)
	assert_true(CraftingSystem.craft(_request(_fire, _missile), _rules, _inventory, _loadout).ok)
	var again := CraftingSystem.craft(_request(_fire, _missile), _rules, _inventory, _loadout)
	assert_false(again.ok)
	assert_eq(again.reason, CraftingSystem.REASON_MISSING)


func test_crafted_spell_works_in_the_loadout() -> void:
	_inventory.add(_thunder)
	_inventory.add(_missile)
	var result := CraftingSystem.craft(_request(_thunder, _missile), _rules, _inventory, _loadout)
	assert_true(result.ok)
	var crafted := _loadout.selected()
	assert_eq(crafted.data, result.spell)
	assert_true(_loadout.try_cast(Vector2.ZERO, Vector2.RIGHT))
	assert_eq(crafted.current_mana, crafted.data.max_mana - crafted.data.mana_cost)
	var effects := 0
	for child in _root.get_children():
		if child is AreaEffect:
			effects += 1
	assert_eq(effects, 1)
