extends GutTest

const FIRE := SpellData.Element.FIRE
const THUNDER := SpellData.Element.THUNDER
const LAND := SpellData.Element.LAND
const SEA := SpellData.Element.SEA

var _table: ElementTable


func before_each() -> void:
	_table = ElementTable.new()


func test_strong_pairs() -> void:
	for pair in [[FIRE, LAND], [LAND, THUNDER], [THUNDER, SEA], [SEA, FIRE]]:
		assert_eq(_table.multiplier(pair[0], pair[1]), _table.strong_multiplier, "%s vs %s" % pair)


func test_weak_pairs() -> void:
	for pair in [[LAND, FIRE], [THUNDER, LAND], [SEA, THUNDER], [FIRE, SEA]]:
		assert_eq(_table.multiplier(pair[0], pair[1]), _table.weak_multiplier, "%s vs %s" % pair)


func test_same_element_is_neutral() -> void:
	for element in [FIRE, THUNDER, LAND, SEA]:
		assert_eq(_table.multiplier(element, element), _table.neutral_multiplier)


func test_no_element_on_either_side_is_neutral() -> void:
	assert_eq(_table.multiplier(FIRE, SpellData.NO_ELEMENT), _table.neutral_multiplier)
	assert_eq(_table.multiplier(SpellData.NO_ELEMENT, LAND), _table.neutral_multiplier)
	assert_eq(_table.multiplier(SpellData.NO_ELEMENT, SpellData.NO_ELEMENT), _table.neutral_multiplier)


func test_multipliers_are_configurable() -> void:
	_table.strong_multiplier = 3.0
	assert_eq(_table.multiplier(FIRE, LAND), 3.0)


func test_default_table_values() -> void:
	var table := ElementTable.default_table()
	assert_not_null(table)
	assert_eq(table.strong_multiplier, 1.5)
	assert_eq(table.weak_multiplier, 0.5)
	assert_eq(table.neutral_multiplier, 1.0)


func test_effect_for_every_pair() -> void:
	for pair in [[FIRE, LAND], [LAND, THUNDER], [THUNDER, SEA], [SEA, FIRE]]:
		assert_eq(_table.effect(pair[0], pair[1]), ElementTable.Effect.VULNERABLE, "%s vs %s" % pair)
	for pair in [[LAND, FIRE], [THUNDER, LAND], [SEA, THUNDER], [FIRE, SEA]]:
		assert_eq(_table.effect(pair[0], pair[1]), ElementTable.Effect.RESISTED, "%s vs %s" % pair)
	for element in [FIRE, THUNDER, LAND, SEA]:
		assert_eq(_table.effect(element, element), ElementTable.Effect.NEUTRAL)
		assert_eq(_table.effect(element, SpellData.NO_ELEMENT), ElementTable.Effect.NEUTRAL)
		assert_eq(_table.effect(SpellData.NO_ELEMENT, element), ElementTable.Effect.NEUTRAL)


func test_unknown_element_values_are_neutral() -> void:
	assert_eq(_table.effect(FIRE, 99), ElementTable.Effect.NEUTRAL)
	assert_eq(_table.effect(99, FIRE), ElementTable.Effect.NEUTRAL)
	assert_eq(_table.multiplier(99, 99), _table.neutral_multiplier)


func test_multiplier_agrees_with_effect() -> void:
	assert_eq(_table.multiplier(FIRE, LAND), _table.strong_multiplier)
	assert_eq(_table.multiplier(FIRE, SEA), _table.weak_multiplier)
	assert_eq(_table.multiplier(FIRE, FIRE), _table.neutral_multiplier)
