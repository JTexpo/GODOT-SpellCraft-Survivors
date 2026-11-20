extends GutTest

const S := StatBonuses.Stat

var _catalog: EquipmentCatalog
var _profile: PlayerProfile


func before_each() -> void:
	_catalog = EquipmentCatalog.default_catalog()
	_profile = PlayerProfile.new()


func _snapshot() -> Dictionary:
	return _profile.to_dict().duplicate(true)


func test_buy_with_exactly_enough_gold_succeeds() -> void:
	_profile.add_gold(100)
	var result := ShopSystem.buy(_profile, _catalog, &"robe_ember")
	assert_true(result.ok)
	assert_eq(result.reason, "")
	assert_eq(result.item.id, &"robe_ember")
	assert_eq(_profile.gold, 0)
	assert_true(_profile.owns(&"robe_ember"))
	assert_eq(_profile.equipped_id(EquipmentData.Slot.ROBE), &"robe_ember")


func test_buy_with_one_gold_too_few_fails_and_changes_nothing() -> void:
	_profile.add_gold(99)
	var before := _snapshot()
	var result := ShopSystem.buy(_profile, _catalog, &"robe_ember")
	assert_false(result.ok)
	assert_eq(result.reason, ShopSystem.REASON_BROKE)
	assert_eq(_snapshot(), before)


func test_buying_twice_fails_and_charges_nothing_more() -> void:
	_profile.add_gold(300)
	ShopSystem.buy(_profile, _catalog, &"robe_ember")
	var before := _snapshot()
	var result := ShopSystem.buy(_profile, _catalog, &"robe_ember")
	assert_false(result.ok)
	assert_eq(result.reason, ShopSystem.REASON_OWNED)
	assert_eq(_snapshot(), before)
	assert_eq(_profile.gold, 200)


func test_buying_an_unknown_id_fails_and_changes_nothing() -> void:
	_profile.add_gold(500)
	var before := _snapshot()
	for id in [&"nothing", &""]:
		var result := ShopSystem.buy(_profile, _catalog, id)
		assert_false(result.ok)
		assert_eq(result.reason, ShopSystem.REASON_UNKNOWN)
		assert_null(result.item)
	assert_eq(_snapshot(), before)


func test_buy_equips_into_the_items_slot_and_keeps_the_replaced_item_owned() -> void:
	_profile.add_gold(500)
	ShopSystem.buy(_profile, _catalog, &"robe_ember")
	ShopSystem.buy(_profile, _catalog, &"robe_tide")
	assert_eq(_profile.equipped_id(EquipmentData.Slot.ROBE), &"robe_tide")
	assert_true(_profile.owns(&"robe_ember"))
	assert_eq(_profile.gold, 300)


func test_hat_and_hood_share_one_slot() -> void:
	_profile.add_gold(500)
	ShopSystem.buy(_profile, _catalog, &"hat_mana")
	ShopSystem.buy(_profile, _catalog, &"hood_swift")
	assert_eq(_profile.equipped_id(EquipmentData.Slot.HEADWEAR), &"hood_swift")
	assert_true(_profile.owns(&"hat_mana"))


func test_wand_and_staff_share_one_slot() -> void:
	_profile.add_gold(1000)
	ShopSystem.buy(_profile, _catalog, &"wand_quick")
	ShopSystem.buy(_profile, _catalog, &"staff_oak")
	assert_eq(_profile.equipped_id(EquipmentData.Slot.WEAPON), &"staff_oak")
	assert_true(_profile.owns(&"wand_quick"))


func test_equip_requires_ownership_and_costs_nothing() -> void:
	_profile.add_gold(500)
	ShopSystem.buy(_profile, _catalog, &"robe_ember")
	ShopSystem.buy(_profile, _catalog, &"robe_tide")
	var gold := _profile.gold
	var result := ShopSystem.equip(_profile, _catalog, &"robe_ember")
	assert_true(result.ok)
	assert_eq(_profile.equipped_id(EquipmentData.Slot.ROBE), &"robe_ember")
	assert_eq(_profile.gold, gold)
	var before := _snapshot()
	var not_owned := ShopSystem.equip(_profile, _catalog, &"robe_storm")
	assert_false(not_owned.ok)
	assert_eq(not_owned.reason, ShopSystem.REASON_NOT_OWNED)
	assert_eq(_snapshot(), before)


func test_equip_an_unknown_id_fails() -> void:
	var before := _snapshot()
	var result := ShopSystem.equip(_profile, _catalog, &"nothing")
	assert_false(result.ok)
	assert_eq(result.reason, ShopSystem.REASON_UNKNOWN)
	assert_eq(_snapshot(), before)


func test_unequip_empties_the_slot_and_keeps_the_item() -> void:
	_profile.add_gold(100)
	ShopSystem.buy(_profile, _catalog, &"robe_ember")
	assert_true(ShopSystem.unequip(_profile, EquipmentData.Slot.ROBE))
	assert_eq(_profile.equipped_id(EquipmentData.Slot.ROBE), &"")
	assert_true(_profile.owns(&"robe_ember"))


func test_unequip_an_empty_slot_returns_false() -> void:
	assert_false(ShopSystem.unequip(_profile, EquipmentData.Slot.WEAPON))
	assert_false(ShopSystem.unequip(_profile, 9))


func test_bonuses_sum_the_equipped_items() -> void:
	_profile.add_gold(1000)
	ShopSystem.buy(_profile, _catalog, &"robe_ember")
	ShopSystem.buy(_profile, _catalog, &"wand_quick")
	ShopSystem.buy(_profile, _catalog, &"hat_swift")
	var bonuses := ShopSystem.bonuses(_profile, _catalog)
	assert_almost_eq(bonuses.fraction(S.DAMAGE_FIRE), 0.15, 0.0001)
	assert_almost_eq(bonuses.fraction(S.CAST_SPEED), 0.25, 0.0001)
	assert_almost_eq(bonuses.fraction(S.SPELL_DAMAGE), -0.15, 0.0001)
	assert_almost_eq(bonuses.fraction(S.CAST_TWICE_CHANCE), 0.10, 0.0001)
	assert_almost_eq(bonuses.fraction(S.SPEED), 0.10, 0.0001)
	assert_eq(bonuses.fraction(S.HEALTH), 0.0)


func test_bonuses_are_empty_with_nothing_equipped() -> void:
	_profile.grant(&"robe_ember")
	var bonuses := ShopSystem.bonuses(_profile, _catalog)
	assert_eq(bonuses.fraction(S.DAMAGE_FIRE), 0.0)


func test_bonuses_skip_unowned_unknown_and_misplaced_equipped_ids() -> void:
	_profile.equip(0, &"robe_ember")
	_profile.equip(1, &"no_such_item")
	_profile.grant(&"wand_quick")
	_profile.equip(2, &"wand_quick")
	var bonuses := ShopSystem.bonuses(_profile, _catalog)
	assert_eq(bonuses.fraction(S.DAMAGE_FIRE), 0.0, "not owned")
	assert_eq(bonuses.fraction(S.CAST_SPEED), 0.0, "a wand in the headwear slot is ignored")


func test_failed_actions_never_touch_the_profile() -> void:
	_profile.add_gold(50)
	_profile.grant(&"hat_mana")
	_profile.equip(2, &"hat_mana")
	var before := _snapshot()
	ShopSystem.buy(_profile, _catalog, &"staff_elder")
	ShopSystem.buy(_profile, _catalog, &"hat_mana")
	ShopSystem.buy(_profile, _catalog, &"nothing")
	ShopSystem.equip(_profile, _catalog, &"robe_tide")
	ShopSystem.equip(_profile, _catalog, &"nothing")
	ShopSystem.unequip(_profile, EquipmentData.Slot.ROBE)
	assert_eq(_snapshot(), before)


func test_can_afford() -> void:
	var item := _catalog.find(&"robe_ember")
	_profile.add_gold(99)
	assert_false(ShopSystem.can_afford(_profile, item))
	_profile.add_gold(1)
	assert_true(ShopSystem.can_afford(_profile, item))
