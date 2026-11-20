extends GutTest


func _spell(copies: int, ground: bool = false, range_px: float = 100.0, size: float = 20.0) -> SpellData:
	var area := AreaData.new()
	area.default_range = range_px
	area.default_size = size
	area.needs_ground_target = ground
	var spell := SpellData.new()
	spell.area_data = area
	spell.copies = copies
	return spell


func _angle_of(vector: Vector2) -> float:
	return vector.angle()


func _assert_angle(vector: Vector2, degrees: float, message: String = "") -> void:
	assert_almost_eq(absf(angle_difference(vector.angle(), deg_to_rad(degrees))), 0.0, 0.0001, message)


func test_one_copy_is_one_shot_with_the_given_direction_and_target() -> void:
	var shots := CastPattern.shots(_spell(1), Vector2(5, 5), Vector2.RIGHT, Vector2(50, 5))
	assert_eq(shots.size(), 1)
	assert_eq(shots[0].direction, Vector2.RIGHT)
	assert_eq(shots[0].target, Vector2(50, 5))


func test_zero_and_negative_copies_are_one_shot() -> void:
	for copies in [0, -1, -9]:
		assert_eq(CastPattern.shots(_spell(copies), Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0)).size(), 1, "copies %d" % copies)
		assert_eq(CastPattern.shots(_spell(copies, true), Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0)).size(), 1, "ground, copies %d" % copies)


func test_aimed_ring_directions() -> void:
	for copies in [2, 3, 4, 5]:
		var shots := CastPattern.shots(_spell(copies), Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0))
		assert_eq(shots.size(), copies)
		for i in copies:
			_assert_angle(shots[i].direction, 360.0 * i / copies, "%d copies, shot %d" % [copies, i])


func test_aimed_ring_rotates_with_the_aim() -> void:
	var shots := CastPattern.shots(_spell(2), Vector2.ZERO, Vector2.DOWN, Vector2(0, 50))
	_assert_angle(shots[0].direction, 90.0)
	_assert_angle(shots[1].direction, -90.0)


func test_every_aimed_shot_has_a_unit_direction_and_a_target_on_its_ray() -> void:
	var origin := Vector2(10, 20)
	var shots := CastPattern.shots(_spell(5), origin, Vector2.RIGHT, origin + Vector2(80, 0))
	for shot in shots:
		assert_almost_eq(shot.direction.length(), 1.0, 0.0001)
		assert_almost_eq(origin.distance_to(shot.target), 80.0, 0.001)
		assert_almost_eq((shot.target - origin).normalized().distance_to(shot.direction), 0.0, 0.0001)


func test_ground_ring_first_zone_is_at_the_clamped_target() -> void:
	var shots := CastPattern.shots(_spell(1, true), Vector2.ZERO, Vector2.RIGHT, Vector2(300, 0))
	assert_eq(shots[0].target, Vector2(100, 0))
	var near := CastPattern.shots(_spell(1, true), Vector2.ZERO, Vector2.RIGHT, Vector2(40, 0))
	assert_eq(near[0].target, Vector2(40, 0))


func test_ground_ring_places_the_others_around_it() -> void:
	var shots := CastPattern.shots(_spell(3, true), Vector2.ZERO, Vector2.RIGHT, Vector2(300, 0))
	assert_eq(shots.size(), 3)
	assert_eq(shots[0].target, Vector2(100, 0))
	assert_almost_eq(shots[1].target.distance_to(shots[0].target), 30.0, 0.001)
	assert_almost_eq(shots[2].target.distance_to(shots[0].target), 30.0, 0.001)
	assert_almost_eq(shots[1].target.x, 130.0, 0.001)
	assert_almost_eq(shots[2].target.x, 70.0, 0.001)
	for shot in shots:
		assert_eq(shot.direction, Vector2.RIGHT, "ground shots keep the aim direction")


func test_ground_ring_with_the_target_on_the_player() -> void:
	var shots := CastPattern.shots(_spell(4, true), Vector2(7, 7), Vector2.RIGHT, Vector2(7, 7))
	assert_eq(shots[0].target, Vector2(7, 7))
	for shot in shots:
		assert_true(shot.target.is_finite())


func test_the_shot_count_matches_the_copies_in_both_modes() -> void:
	for copies in [1, 2, 3, 4, 5]:
		assert_eq(CastPattern.shots(_spell(copies), Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0)).size(), copies)
		assert_eq(CastPattern.shots(_spell(copies, true), Vector2.ZERO, Vector2.RIGHT, Vector2(50, 0)).size(), copies)
