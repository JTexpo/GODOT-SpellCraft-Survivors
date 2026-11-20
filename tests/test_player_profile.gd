extends GutTest

var _track: LevelTrack


func before_each() -> void:
	_track = LevelTrack.default_track()


func test_fresh_profile_is_level_one_with_no_xp() -> void:
	var profile := PlayerProfile.new()
	assert_eq(profile.total_xp, 0)
	assert_eq(profile.level(_track), 1)


func test_add_xp_ignores_zero_and_negative() -> void:
	var profile := PlayerProfile.new()
	profile.add_xp(10)
	profile.add_xp(0)
	profile.add_xp(-4)
	assert_eq(profile.total_xp, 10)
	profile.add_xp(20)
	assert_eq(profile.level(_track), 2)


func test_xp_round_trips_through_a_dictionary() -> void:
	var profile := PlayerProfile.new()
	profile.add_xp(1234)
	var restored := PlayerProfile.from_dict(profile.to_dict())
	assert_not_null(restored)
	assert_eq(restored.total_xp, 1234)


func test_old_save_with_buff_picks_still_loads_and_the_field_is_dropped() -> void:
	var old := {"version": SaveGame.VERSION, "total_xp": 40, "buff_picks": {"7": "buff_damage"}}
	var profile := PlayerProfile.from_dict(old)
	assert_not_null(profile)
	assert_eq(profile.total_xp, 40)
	assert_false(profile.to_dict().has("buff_picks"))


func test_from_dict_does_not_require_buff_picks() -> void:
	assert_not_null(PlayerProfile.from_dict({"version": SaveGame.VERSION, "total_xp": 5}))


func test_from_dict_accepts_what_json_produces() -> void:
	var parsed = JSON.parse_string(JSON.stringify(PlayerProfile.new().to_dict()))
	assert_not_null(PlayerProfile.from_dict(parsed))
	var with_xp := {"version": 1.0, "total_xp": 55.0}
	assert_eq(PlayerProfile.from_dict(with_xp).total_xp, 55)


func test_from_dict_rejects_bad_shapes() -> void:
	var good := {"version": SaveGame.VERSION, "total_xp": 5}
	assert_not_null(PlayerProfile.from_dict(good))
	var cases := {
		"missing total_xp": {"version": SaveGame.VERSION},
		"missing version": {"total_xp": 5},
		"string total_xp": {"version": SaveGame.VERSION, "total_xp": "5"},
		"fractional total_xp": {"version": SaveGame.VERSION, "total_xp": 5.5},
		"negative total_xp": {"version": SaveGame.VERSION, "total_xp": -5},
		"wrong version": {"version": SaveGame.VERSION + 1, "total_xp": 5},
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
