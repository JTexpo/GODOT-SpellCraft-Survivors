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
