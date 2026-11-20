extends GutTest

var _track: LevelTrack


func before_each() -> void:
	_track = LevelTrack.default_track()


func test_fresh_profile_is_level_one_with_no_xp() -> void:
	var profile := PlayerProfile.new()
	assert_eq(profile.total_xp, 0)
	assert_eq(profile.level(_track), 1)
	assert_true(profile.buff_picks.is_empty())


func test_add_xp_ignores_zero_and_negative() -> void:
	var profile := PlayerProfile.new()
	profile.add_xp(10)
	profile.add_xp(0)
	profile.add_xp(-4)
	assert_eq(profile.total_xp, 10)
	profile.add_xp(20)
	assert_eq(profile.level(_track), 2)


func test_picks_round_trip_through_a_dictionary() -> void:
	var profile := PlayerProfile.new()
	profile.add_xp(1234)
	profile.set_pick(7, &"buff_damage")
	profile.set_pick(12, &"buff_max_mana")
	var restored := PlayerProfile.from_dict(profile.to_dict())
	assert_not_null(restored)
	assert_eq(restored.total_xp, 1234)
	assert_eq(restored.pick(7), &"buff_damage")
	assert_eq(restored.pick(12), &"buff_max_mana")
	assert_eq(restored.pick(17), &"")


func test_from_dict_accepts_what_json_produces() -> void:
	var parsed = JSON.parse_string(JSON.stringify(PlayerProfile.new().to_dict()))
	assert_not_null(PlayerProfile.from_dict(parsed))
	var with_xp := {"version": 1.0, "total_xp": 55.0, "buff_picks": {"7": "buff_damage"}}
	var profile := PlayerProfile.from_dict(with_xp)
	assert_eq(profile.total_xp, 55)
	assert_eq(profile.pick(7), &"buff_damage")


func test_from_dict_rejects_bad_shapes() -> void:
	var good := {"version": SaveGame.VERSION, "total_xp": 5, "buff_picks": {}}
	assert_not_null(PlayerProfile.from_dict(good))
	var cases := {
		"missing total_xp": {"version": SaveGame.VERSION, "buff_picks": {}},
		"missing version": {"total_xp": 5, "buff_picks": {}},
		"missing buff_picks": {"version": SaveGame.VERSION, "total_xp": 5},
		"string total_xp": {"version": SaveGame.VERSION, "total_xp": "5", "buff_picks": {}},
		"fractional total_xp": {"version": SaveGame.VERSION, "total_xp": 5.5, "buff_picks": {}},
		"negative total_xp": {"version": SaveGame.VERSION, "total_xp": -5, "buff_picks": {}},
		"picks not a dictionary": {"version": SaveGame.VERSION, "total_xp": 5, "buff_picks": []},
		"non-integer pick key": {"version": SaveGame.VERSION, "total_xp": 5, "buff_picks": {"seven": "buff_damage"}},
		"non-string pick value": {"version": SaveGame.VERSION, "total_xp": 5, "buff_picks": {"7": 3}},
		"wrong version": {"version": SaveGame.VERSION + 1, "total_xp": 5, "buff_picks": {}},
	}
	for name in cases:
		assert_null(PlayerProfile.from_dict(cases[name]), name)


func test_stat_bonuses_for_level() -> void:
	var level_one := StatBonuses.for_level(_track, 1)
	assert_eq(level_one.multiplier(StatBonuses.Stat.SPEED), 1.0)
	assert_eq(level_one.multiplier(StatBonuses.Stat.HEALTH), 1.0)
	assert_eq(level_one.multiplier(StatBonuses.Stat.SPELL_MANA), 1.0)
	var level_five := StatBonuses.for_level(_track, 5)
	assert_almost_eq(level_five.multiplier(StatBonuses.Stat.SPEED), 1.08, 0.0001)
	assert_almost_eq(level_five.multiplier(StatBonuses.Stat.HEALTH), 1.2, 0.0001)
	assert_almost_eq(level_five.multiplier(StatBonuses.Stat.SPELL_MANA), 1.15, 0.0001)
	var level_twenty := StatBonuses.for_level(_track, 20)
	assert_almost_eq(level_twenty.multiplier(StatBonuses.Stat.SPEED), 1.32, 0.0001)
	assert_almost_eq(level_twenty.multiplier(StatBonuses.Stat.HEALTH), 1.8, 0.0001)
	assert_almost_eq(level_twenty.multiplier(StatBonuses.Stat.SPELL_MANA), 1.3, 0.0001)
	assert_almost_eq(level_twenty.fraction(StatBonuses.Stat.SPEED), 0.32, 0.0001)
