extends GutTest

const E := SpellData.Element
# path, element, damage, interval, cost, max mana, speed, knockback
const SPELLS := [
	["res://resources/spells/fire.tres", E.FIRE, 10.0, 0.35, 1.0, 40.0, 220.0, 120.0],
	["res://resources/spells/thunder.tres", E.THUNDER, 7.0, 0.18, 1.0, 60.0, 300.0, 80.0],
	["res://resources/spells/land.tres", E.LAND, 18.0, 0.7, 2.0, 40.0, 160.0, 220.0],
	["res://resources/spells/sea.tres", E.SEA, 9.0, 0.3, 1.0, 45.0, 200.0, 60.0],
]


func test_spells_match_starting_values() -> void:
	for row in SPELLS:
		var spell := load(row[0]) as SpellData
		assert_not_null(spell, row[0])
		assert_eq(spell.elements, [row[1]], row[0])
		assert_eq(spell.primary_element(), row[1], row[0])
		assert_eq(spell.area, SpellData.AreaType.MISSILE, row[0])
		assert_eq(spell.max_hits, 1, row[0])
		assert_eq(spell.damage, row[2], row[0])
		assert_eq(spell.cast_interval, row[3], row[0])
		assert_eq(spell.mana_cost, row[4], row[0])
		assert_eq(spell.max_mana, row[5], row[0])
		assert_eq(spell.projectile_speed, row[6], row[0])
		assert_eq(spell.knockback, row[7], row[0])
		assert_eq(spell.projectile_lifetime, 1.2, row[0])
		assert_true(spell.mana_cost <= spell.max_mana, row[0])


func test_empty_spell_has_no_primary_element() -> void:
	assert_eq(SpellData.new().primary_element(), SpellData.NO_ELEMENT)
