extends GutTest

const FIRE := SpellData.Element.FIRE
const THUNDER := SpellData.Element.THUNDER
const LAND := SpellData.Element.LAND
const SEA := SpellData.Element.SEA
const NONE := SpellData.NO_ELEMENT
const VULNERABLE := ElementTable.Effect.VULNERABLE
const RESISTED := ElementTable.Effect.RESISTED
const NEUTRAL := ElementTable.Effect.NEUTRAL

var _table: ElementTable


func before_each() -> void:
	_table = ElementTable.new()


func _resolve(elements: Array, defender: int, scale: float = 1.0, ignores: bool = false) -> HitResult:
	return DamageSystem.resolve(10.0, elements, defender, scale, ignores, _table)


func test_single_element_matches_the_old_calculation() -> void:
	for attacker in [FIRE, THUNDER, LAND, SEA, NONE]:
		for defender in [FIRE, THUNDER, LAND, SEA, NONE]:
			var result := _resolve([attacker], defender)
			assert_eq(result.amount, DamageSystem.calculate(10.0, attacker, defender, _table), "%d vs %d" % [attacker, defender])
			assert_eq(result.effect, DamageSystem.effect(attacker, defender, _table), "%d vs %d" % [attacker, defender])
			assert_eq(result.amount, 10.0 * _table.multiplier(attacker, defender))


func test_hybrid_uses_the_best_element() -> void:
	var cases := [[FIRE, 15.0, VULNERABLE], [LAND, 15.0, VULNERABLE], [THUNDER, 10.0, NEUTRAL], [SEA, 10.0, NEUTRAL]]
	for case in cases:
		for elements in [[FIRE, SEA], [SEA, FIRE]]:
			var result := _resolve(elements, case[0])
			assert_eq(result.amount, case[1], "%s vs %d" % [elements, case[0]])
			assert_eq(result.effect, case[2], "%s vs %d" % [elements, case[0]])


func test_a_hybrid_is_never_resisted_when_another_element_is_neutral() -> void:
	assert_eq(_resolve([FIRE, SEA], SEA).amount, 10.0, "Fire alone would be resisted here")
	assert_eq(_resolve([FIRE], SEA).amount, 5.0)


func test_tie_picks_the_first_element() -> void:
	# With the strong multiplier set to neutral, Sea against Fire ties with Fire against Fire, but
	# the two hits have different effects, so the winner shows which element was first.
	_table.strong_multiplier = 1.0
	assert_eq(_resolve([SEA, FIRE], FIRE).effect, VULNERABLE, "Sea is first and wins the tie")
	assert_eq(_resolve([FIRE, SEA], FIRE).effect, NEUTRAL, "Fire is first and wins the tie")
	assert_eq(_resolve([FIRE, SEA], FIRE).amount, 10.0)


func test_a_strictly_better_second_element_wins() -> void:
	assert_eq(_resolve([FIRE, SEA], FIRE).effect, VULNERABLE, "Sea's strong hit beats Fire's neutral one")


func test_double_vulnerability_scales_only_the_bonus() -> void:
	assert_eq(_resolve([FIRE], LAND, 1.0).amount, 15.0)
	assert_eq(_resolve([FIRE], LAND, 2.0).amount, 20.0)
	assert_eq(_resolve([FIRE], LAND, 3.0).amount, 25.0)
	assert_eq(_resolve([FIRE], LAND, 2.0).effect, VULNERABLE)
	assert_eq(_resolve([FIRE], FIRE, 5.0).amount, 10.0, "a neutral hit has no bonus to scale")
	assert_eq(_resolve([FIRE], SEA, 5.0).amount, 5.0, "a resisted hit is not scaled")


func test_scale_below_one_never_makes_the_bonus_negative() -> void:
	assert_eq(_resolve([FIRE], LAND, 0.0).amount, 10.0, "no bonus, but never a penalty")
	assert_eq(_resolve([FIRE], LAND, -1.0).amount, 10.0)
	assert_eq(_resolve([FIRE], LAND, 0.5).amount, 12.5)


func test_ignore_resistance_makes_a_resisted_hit_neutral() -> void:
	var result := _resolve([FIRE], SEA, 1.0, true)
	assert_eq(result.amount, 10.0)
	assert_eq(result.effect, NEUTRAL)
	assert_eq(_resolve([FIRE], LAND, 1.0, true).effect, VULNERABLE, "a strong hit stays strong")


func test_empty_and_unknown_elements_are_neutral() -> void:
	for elements in [[], [NONE], [99], [-7]]:
		for defender in [FIRE, NONE, 99]:
			var result := _resolve(elements, defender)
			assert_eq(result.amount, 10.0, "%s vs %d" % [elements, defender])
			assert_eq(result.effect, NEUTRAL)


func test_a_table_with_a_strong_multiplier_at_or_below_neutral_gives_no_bonus() -> void:
	for strong in [1.0, 0.8]:
		_table.strong_multiplier = strong
		assert_lte(_resolve([FIRE], LAND, 3.0).amount, 10.0 + 0.0001, "strong = %s" % strong)


func test_amount_never_goes_below_zero() -> void:
	_table.weak_multiplier = -1.0
	assert_eq(_resolve([FIRE], SEA).amount, 0.0)
	assert_eq(DamageSystem.resolve(-5.0, [FIRE], FIRE, 1.0, false, _table).amount, 0.0)
