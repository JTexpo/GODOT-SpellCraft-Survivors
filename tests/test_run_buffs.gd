extends GutTest


func test_fresh_run_buffs_have_no_picks() -> void:
	var buffs := RunBuffs.new()
	assert_true(buffs.picks.is_empty())
	assert_eq(buffs.pick(7), &"")


func test_set_and_read_a_pick() -> void:
	var buffs := RunBuffs.new()
	buffs.set_pick(12, &"buff_damage")
	assert_eq(buffs.pick(12), &"buff_damage")
	assert_eq(buffs.pick(7), &"")


func test_picks_are_per_instance() -> void:
	var first := RunBuffs.new()
	var second := RunBuffs.new()
	first.set_pick(7, &"buff_damage")
	assert_eq(second.pick(7), &"")
