extends GutTest

const S := StatBonuses.Stat
const FIRE := SpellData.Element.FIRE
const SEA := SpellData.Element.SEA


func _bonuses(values: Dictionary = {}) -> StatBonuses:
	var bonuses := StatBonuses.new()
	for stat in values:
		bonuses.add(stat, values[stat])
	return bonuses


func test_no_bonuses_give_a_scale_of_one_and_an_unchanged_interval_and_pool() -> void:
	var none := StatBonuses.new()
	assert_eq(CastMath.damage_scale([FIRE], none), 1.0)
	assert_eq(CastMath.interval(0.35, 0.0), 0.35)
	assert_eq(CastMath.pool(100.0, 0.0), 100.0)


func test_spell_damage_and_element_bonus_multiply() -> void:
	var bonuses := _bonuses({S.SPELL_DAMAGE: 0.25, S.DAMAGE_FIRE: 0.2})
	assert_almost_eq(CastMath.damage_scale([FIRE], bonuses), 1.5, 0.0001)


func test_hybrid_element_bonus_is_the_mean() -> void:
	var bonuses := _bonuses({S.DAMAGE_FIRE: 0.2})
	assert_almost_eq(CastMath.damage_scale([FIRE, SEA], bonuses), 1.1, 0.0001)


func test_a_bonus_for_another_element_does_not_apply() -> void:
	assert_eq(CastMath.damage_scale([FIRE], _bonuses({S.DAMAGE_SEA: 0.5})), 1.0)


func test_scale_is_floored_at_a_tenth() -> void:
	assert_almost_eq(CastMath.damage_scale([FIRE], _bonuses({S.SPELL_DAMAGE: -0.99})), 0.1, 0.0001)
	assert_eq(CastMath.damage_scale([FIRE], _bonuses({S.SPELL_DAMAGE: -3.0})), CastMath.MIN_DAMAGE_SCALE)
	assert_eq(CastMath.damage_scale([FIRE], _bonuses({S.DAMAGE_FIRE: -2.0})), CastMath.MIN_DAMAGE_SCALE)


func test_no_elements_use_only_spell_damage() -> void:
	var bonuses := _bonuses({S.SPELL_DAMAGE: 0.25, S.DAMAGE_FIRE: 0.5})
	assert_almost_eq(CastMath.damage_scale([], bonuses), 1.25, 0.0001)
	assert_almost_eq(CastMath.damage_scale([SpellData.NO_ELEMENT], bonuses), 1.25, 0.0001)


func test_interval_divides_by_one_plus_cast_speed() -> void:
	assert_almost_eq(CastMath.interval(0.35, 0.25), 0.28, 0.0001)
	assert_almost_eq(CastMath.interval(0.35, 1.0), 0.175, 0.0001)


func test_negative_cast_speed_slows_the_spell() -> void:
	assert_almost_eq(CastMath.interval(0.35, -0.15), 0.35 / 0.85, 0.0001)
	assert_gt(CastMath.interval(0.35, -0.3), 0.35)


func test_interval_floor_and_extreme_speeds() -> void:
	assert_eq(CastMath.interval(0.35, 100.0), CastMath.MIN_INTERVAL)
	assert_eq(CastMath.interval(0.02, 5.0), 0.02, "a base under the floor is never raised")
	var very_slow := CastMath.interval(0.35, -2.0)
	assert_gt(very_slow, 0.0)
	assert_false(is_inf(very_slow))
	assert_false(is_nan(very_slow))
	assert_almost_eq(very_slow, 3.5, 0.0001)


func test_pool_scales_with_spell_mana() -> void:
	assert_almost_eq(CastMath.pool(100.0, 0.3), 130.0, 0.0001)
	assert_almost_eq(CastMath.pool(1000.0, 0.15), 1150.0, 0.0001)


func test_chance_is_clamped_to_zero_and_one() -> void:
	assert_eq(CastMath.chance(_bonuses({S.CAST_TWICE_CHANCE: 1.5}), S.CAST_TWICE_CHANCE), 1.0)
	assert_eq(CastMath.chance(_bonuses({S.CAST_TWICE_CHANCE: -0.2}), S.CAST_TWICE_CHANCE), 0.0)
	assert_almost_eq(CastMath.chance(_bonuses({S.DOUBLE_DAMAGE_CHANCE: 0.3}), S.DOUBLE_DAMAGE_CHANCE), 0.3, 0.0001)
	assert_eq(CastMath.chance(StatBonuses.new(), S.CAST_TWICE_CHANCE), 0.0)
