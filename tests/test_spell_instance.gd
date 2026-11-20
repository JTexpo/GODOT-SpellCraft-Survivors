extends GutTest

var _data: SpellData
var _spell: SpellInstance


func before_each() -> void:
	_data = SpellData.new()
	_data.max_mana = 3.0
	_data.mana_cost = 1.0
	_data.cast_interval = 0.5
	_spell = SpellInstance.new(_data)


func test_starts_at_full_mana() -> void:
	assert_eq(_spell.current_mana, 3.0)
	assert_eq(_spell.mana_ratio(), 1.0)


func test_cast_spends_exactly_the_mana_cost() -> void:
	assert_true(_spell.cast())
	assert_eq(_spell.current_mana, 2.0)


func test_cooldown_blocks_then_allows() -> void:
	assert_true(_spell.cast())
	assert_false(_spell.cast())
	assert_eq(_spell.current_mana, 2.0)
	_spell.tick(0.5)
	assert_true(_spell.cast())


func test_depleted_spell_never_casts_and_never_regenerates() -> void:
	for i in 3:
		assert_true(_spell.cast())
		_spell.tick(0.5)
	assert_eq(_spell.current_mana, 0.0)
	assert_false(_spell.has_mana())
	assert_false(_spell.cast())
	_spell.tick(100.0)
	assert_eq(_spell.current_mana, 0.0)
	assert_false(_spell.can_cast())


func test_restore_mana_refills_and_clamps() -> void:
	_spell.cast()
	_spell.restore_mana()
	assert_eq(_spell.current_mana, 3.0)
	_spell.tick(1.0)
	_spell.cast()
	assert_eq(_spell.current_mana, 2.0)
	_spell.restore_mana(0.5)
	assert_eq(_spell.current_mana, 2.5)
	_spell.restore_mana(10.0)
	assert_eq(_spell.current_mana, 3.0)


func test_mana_changed_emits_on_cast_and_restore() -> void:
	watch_signals(_spell)
	_spell.cast()
	assert_signal_emitted_with_parameters(_spell, "mana_changed", [2.0, 3.0])
	_spell.restore_mana()
	assert_signal_emitted_with_parameters(_spell, "mana_changed", [3.0, 3.0])


func test_instances_from_one_definition_do_not_share_mana() -> void:
	var other := SpellInstance.new(_data)
	_spell.cast()
	assert_eq(_spell.current_mana, 2.0)
	assert_eq(other.current_mana, 3.0)
	assert_eq(_data.max_mana, 3.0)


func test_mana_bonus_raises_pool_and_current_by_the_same_amount() -> void:
	_data.max_mana = 100.0
	var spell := SpellInstance.new(_data)
	spell.current_mana = 40.0
	spell.set_max_mana_bonus(0.15)
	assert_almost_eq(spell.max_mana(), 115.0, 0.0001)
	assert_almost_eq(spell.current_mana, 55.0, 0.0001)


func test_new_instance_with_a_bonus_set_later_starts_full() -> void:
	_data.max_mana = 100.0
	var spell := SpellInstance.new(_data)
	spell.set_max_mana_bonus(0.3)
	assert_almost_eq(spell.current_mana, 130.0, 0.0001)


func test_lowering_the_bonus_clamps_current() -> void:
	_data.max_mana = 100.0
	var spell := SpellInstance.new(_data)
	spell.set_max_mana_bonus(0.3)
	spell.set_max_mana_bonus(0.0)
	assert_almost_eq(spell.current_mana, 100.0, 0.0001)
	assert_almost_eq(spell.max_mana(), 100.0, 0.0001)


func test_mana_ratio_and_restore_use_the_bonus_pool() -> void:
	_data.max_mana = 100.0
	var spell := SpellInstance.new(_data)
	spell.set_max_mana_bonus(0.5)
	spell.current_mana = 75.0
	assert_almost_eq(spell.mana_ratio(), 0.5, 0.0001)
	spell.restore_mana()
	assert_almost_eq(spell.current_mana, 150.0, 0.0001)


func test_mana_changed_reports_the_bonus_pool() -> void:
	_data.max_mana = 10.0
	_data.mana_cost = 1.0
	var spell := SpellInstance.new(_data)
	spell.set_max_mana_bonus(0.5)
	watch_signals(spell)
	spell.cast()
	assert_signal_emitted_with_parameters(spell, "mana_changed", [14.0, 15.0])


func test_cost_per_cast_is_unchanged_by_the_bonus() -> void:
	_data.max_mana = 10.0
	_data.mana_cost = 1.0
	var spell := SpellInstance.new(_data)
	spell.set_max_mana_bonus(0.5)
	spell.cast()
	assert_almost_eq(spell.current_mana, 14.0, 0.0001)


func test_cast_speed_shortens_the_cooldown_after_a_cast() -> void:
	_data.max_mana = 10.0
	var spell := SpellInstance.new(_data)
	spell.set_cast_speed_bonus(0.25)
	spell.cast()
	assert_almost_eq(spell.cooldown_left, 0.4, 0.0001)
	assert_almost_eq(spell.effective_interval(), 0.4, 0.0001)


func test_slower_casting_lengthens_it() -> void:
	_data.max_mana = 10.0
	var spell := SpellInstance.new(_data)
	spell.set_cast_speed_bonus(-0.5)
	spell.cast()
	assert_almost_eq(spell.cooldown_left, 1.0, 0.0001)


func test_no_cast_speed_leaves_the_interval_alone() -> void:
	_data.max_mana = 10.0
	var spell := SpellInstance.new(_data)
	spell.cast()
	assert_eq(spell.cooldown_left, 0.5)


func test_two_instances_never_share_a_cast_speed() -> void:
	var fast := SpellInstance.new(_data)
	var plain := SpellInstance.new(_data)
	fast.set_cast_speed_bonus(0.5)
	assert_eq(plain.effective_interval(), _data.cast_interval)
	assert_eq(_data.cast_interval, 0.5)
