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
