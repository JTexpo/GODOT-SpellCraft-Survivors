extends GutTest

const BASES := ["fire", "thunder", "land", "sea"]
const AREAS := ["line", "cone", "area", "missile", "wave"]

var _rules: CraftingRules


func before_each() -> void:
	_rules = CraftingRules.default_rules()


func _base(name: String) -> ScrollData:
	return load("res://resources/scrolls/base/%s.tres" % name) as ScrollData


func _area(name: String) -> ScrollData:
	return load("res://resources/scrolls/area/%s.tres" % name) as ScrollData


func _normal() -> RangeOption:
	return _rules.option(_rules.normal_index())


func test_fire_missile_at_normal_equals_the_starting_spell_except_its_bigger_pool() -> void:
	var built := SpellBuilder.build(_base("fire"), _area("missile"), _normal())
	var starting := load("res://resources/spells/fire_missile.tres") as SpellData
	assert_not_null(built)
	assert_eq(built.damage, starting.damage)
	assert_eq(built.cast_interval, starting.cast_interval)
	assert_eq(built.mana_cost, starting.mana_cost)
	# The player's first spell has a generous pool (1000) so a run has time to find scrolls.
	# Crafted spells use the Area baseline (100).
	assert_eq(starting.max_mana, 1000.0)
	assert_eq(built.max_mana, 100.0)
	assert_eq(built.projectile_speed, starting.projectile_speed)
	assert_eq(built.knockback, starting.knockback)
	assert_eq(built.max_hits, starting.max_hits)
	assert_eq(built.elements, starting.elements)
	assert_eq(built.color, starting.color)
	assert_eq(built.area_type(), starting.area_type())
	assert_eq(built.range_scale, 1.0)
	assert_eq(built.size_scale, 1.0)


func test_every_base_and_area_pair_builds() -> void:
	for base_name in BASES:
		for area_name in AREAS:
			var base := _base(base_name)
			var area := _area(area_name)
			var built := SpellBuilder.build(base, area, _normal())
			assert_not_null(built, "%s %s" % [base_name, area_name])
			assert_eq(built.primary_element(), base.element)
			assert_eq(built.area_data, area.area_data)
			assert_gt(built.damage, 0.0)
			assert_gt(built.mana_cost, 0.0)
			assert_gte(built.max_mana, built.mana_cost)


func test_longer_range_costs_more_and_gives_fewer_casts() -> void:
	var base := _base("thunder")
	var area := _area("wave")
	var previous: SpellData = null
	for i in _rules.range_options.size():
		var built := SpellBuilder.build(base, area, _rules.option(i))
		assert_eq(built.range_scale, _rules.option(i).range_scale)
		if previous != null:
			assert_gt(built.mana_cost, previous.mana_cost)
			assert_eq(built.max_mana, previous.max_mana)
			assert_lt(built.max_mana / built.mana_cost, previous.max_mana / previous.mana_cost)
		previous = built


func test_land_is_slower_and_heavier_than_thunder() -> void:
	for area_name in AREAS:
		var land := SpellBuilder.build(_base("land"), _area(area_name), _normal())
		var thunder := SpellBuilder.build(_base("thunder"), _area(area_name), _normal())
		assert_gt(land.damage, thunder.damage, area_name)
		assert_gt(land.cast_interval, thunder.cast_interval, area_name)
		assert_gt(thunder.max_mana, land.max_mana, area_name)


func test_name_and_id() -> void:
	var normal := SpellBuilder.build(_base("fire"), _area("missile"), _normal())
	assert_eq(normal.display_name, "Fire Missile")
	assert_eq(normal.id, &"fire_missile_normal")
	var long := SpellBuilder.build(_base("fire"), _area("missile"), _rules.option(2))
	assert_eq(long.display_name, "Fire Missile (Long)")
	assert_eq(long.id, &"fire_missile_long")
	var very_long := SpellBuilder.build(_base("sea"), _area("line"), _rules.option(3))
	assert_eq(very_long.display_name, "Sea Line (Very long)")
	assert_eq(very_long.id, &"sea_line_very_long")
	assert_eq(SpellBuilder.display_name(_base("land"), _area("area"), _normal()), "Land Area")


func test_describe_reports_the_numbers() -> void:
	var built := SpellBuilder.build(_base("land"), _area("area"), _rules.option(2))
	var info := SpellBuilder.describe(built)
	assert_eq(info["name"], "Land Area (Long)")
	assert_eq(info["damage"], built.damage)
	assert_eq(info["interval"], built.cast_interval)
	assert_eq(info["cost"], built.mana_cost)
	assert_eq(info["pool"], built.max_mana)
	assert_almost_eq(info["casts"], built.max_mana / built.mana_cost, 0.0001)
	assert_eq(info["range"], built.effective_range())
	assert_eq(info["area"], "Area")
	assert_eq(SpellBuilder.describe(SpellBuilder.build(_base("fire"), _area("missile"), _normal()))["area"], "Missile")


func test_bad_inputs_return_null() -> void:
	var fire := _base("fire")
	var missile := _area("missile")
	assert_null(SpellBuilder.build(null, missile, _normal()))
	assert_null(SpellBuilder.build(fire, null, _normal()))
	assert_null(SpellBuilder.build(fire, missile, null))
	assert_null(SpellBuilder.build(missile, missile, _normal()), "an Area scroll given as the Base")
	assert_null(SpellBuilder.build(fire, fire, _normal()), "a Base scroll given as the Area")
	var bare := fire.duplicate() as ScrollData
	bare.modifiers = null
	assert_null(SpellBuilder.build(bare, missile, _normal()), "a Base with no modifiers")
	var no_stats := missile.duplicate() as ScrollData
	no_stats.area_data = missile.area_data.duplicate() as AreaData
	no_stats.area_data.base_stats = null
	assert_null(SpellBuilder.build(fire, no_stats, _normal()), "an Area with no baseline")
