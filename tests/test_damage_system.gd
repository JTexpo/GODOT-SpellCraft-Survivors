extends GutTest


func test_passes_damage_through() -> void:
	assert_eq(DamageSystem.calculate(12.0), 12.0)


func test_negative_damage_clamps_to_zero() -> void:
	assert_eq(DamageSystem.calculate(-5.0), 0.0)


func test_strong_element_multiplies_damage() -> void:
	assert_eq(DamageSystem.calculate(10.0, SpellData.Element.FIRE, SpellData.Element.LAND), 15.0)


func test_weak_element_reduces_damage() -> void:
	assert_eq(DamageSystem.calculate(10.0, SpellData.Element.FIRE, SpellData.Element.SEA), 5.0)


func test_no_defender_element_is_unchanged() -> void:
	assert_eq(DamageSystem.calculate(10.0, SpellData.Element.FIRE), 10.0)


func test_custom_table_is_used() -> void:
	var table := ElementTable.new()
	table.strong_multiplier = 2.0
	assert_eq(DamageSystem.calculate(10.0, SpellData.Element.FIRE, SpellData.Element.LAND, table), 20.0)


func test_effect_helper_uses_the_default_table() -> void:
	assert_eq(DamageSystem.effect(SpellData.Element.FIRE, SpellData.Element.LAND), ElementTable.Effect.VULNERABLE)
	assert_eq(DamageSystem.effect(SpellData.Element.FIRE, SpellData.Element.SEA), ElementTable.Effect.RESISTED)
	assert_eq(DamageSystem.effect(SpellData.Element.FIRE, SpellData.NO_ELEMENT), ElementTable.Effect.NEUTRAL)
