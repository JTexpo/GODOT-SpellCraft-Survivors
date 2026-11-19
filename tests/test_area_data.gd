extends GutTest

var _area: AreaData
var _spell: SpellData


func before_each() -> void:
	_area = AreaData.new()
	_area.default_range = 100.0
	_area.default_size = 10.0
	_spell = SpellData.new()
	_spell.area_data = _area


func test_effective_range_and_size_follow_scales() -> void:
	_spell.range_scale = 2.0
	_spell.size_scale = 0.5
	assert_eq(_spell.effective_range(), 200.0)
	assert_eq(_spell.effective_size(), 5.0)


func test_one_area_at_two_ranges() -> void:
	var other := SpellData.new()
	other.area_data = _area
	other.range_scale = 0.5
	assert_eq(_spell.effective_range(), 100.0)
	assert_eq(other.effective_range(), 50.0)


func test_effective_values_never_collapse_to_zero() -> void:
	_spell.range_scale = 0.0
	_spell.size_scale = 0.0
	assert_eq(_spell.effective_range(), SpellData.MIN_RANGE)
	assert_eq(_spell.effective_size(), SpellData.MIN_SIZE)


func test_area_type_comes_from_area_data() -> void:
	_area.type = AreaData.AreaType.WAVE
	assert_eq(_spell.area_type(), AreaData.AreaType.WAVE)


func test_clamp_target_limits_distance_to_range() -> void:
	assert_eq(_spell.clamp_target(Vector2(10, 0), Vector2(500, 0)), Vector2(110, 0))


func test_clamp_target_keeps_closer_points_and_handles_target_on_origin() -> void:
	assert_eq(_spell.clamp_target(Vector2.ZERO, Vector2(50, 0)), Vector2(50, 0))
	var on_origin := _spell.clamp_target(Vector2(7, 7), Vector2(7, 7))
	assert_eq(on_origin, Vector2(7, 7))
	assert_false(is_nan(on_origin.x))
