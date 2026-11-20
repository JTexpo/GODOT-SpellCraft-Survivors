extends GutTest

const ROOT := "res://.godot/save_tests"

var _dir: String
var _track: LevelTrack


func before_each() -> void:
	_dir = "%s/main_%s" % [ROOT, str(randi())]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_track = LevelTrack.default_track()


func after_each() -> void:
	var absolute := ProjectSettings.globalize_path(_dir)
	for file in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute("%s/%s" % [absolute, file])
	DirAccess.remove_absolute(absolute)


func _path() -> String:
	return "%s/save.json" % _dir


func _new_main(save_path: String) -> Main:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	main.save_path = save_path
	(main.get_node("BuffPickScreen") as BuffPickScreen).pause_tree = false
	add_child_autofree(main)
	return main


func _save_at_level(level: int) -> void:
	var profile := PlayerProfile.new()
	profile.total_xp = _track.xp_for_level(level)
	SaveGame.save_profile(profile, _path())


func _stack_total(spell: SpellData) -> int:
	var total := 0
	for id in spell.buff_stacks:
		total += int(spell.buff_stacks[id])
	return total


func _player(main: Main) -> Player:
	return main.get_node("Player") as Player


func _speed(main: Main) -> float:
	return (_player(main).get_node("MoveComponent") as MoveComponent).speed


func test_fresh_run_starts_at_level_one_with_one_slot() -> void:
	var main := _new_main(_path())
	assert_eq(main.profile.total_xp, 0)
	assert_eq(_player(main).progress.level(), 1)
	assert_eq(_player(main).loadout.unlocked_slots, 1)
	assert_eq(_speed(main), 90.0)
	assert_eq(_player(main).health.max_health, 100.0)
	assert_eq((main.get_node("Hud/XpBar") as XpBar).level_text(), "Lv 1")
	assert_false((main.get_node("BuffPickScreen") as BuffPickScreen).is_open())


func test_saved_level_ten_profile_starts_with_three_slots_and_the_bonuses() -> void:
	_save_at_level(10)
	var main := _new_main(_path())
	var player := _player(main)
	assert_eq(player.loadout.unlocked_slots, 3)
	assert_almost_eq(_speed(main), 90.0 * 1.16, 0.001)
	assert_almost_eq(player.health.max_health, 140.0, 0.001)
	assert_almost_eq(player.loadout.mana_bonus, 0.3, 0.0001)
	assert_eq(_stack_total(player.loadout.slots[0].data), 1, "level 7 gave one random buff")
	assert_eq((main.get_node("Hud/XpBar") as XpBar).level_text(), "Lv 10")


func test_killing_an_enemy_drops_a_gem_that_adds_xp_when_collected() -> void:
	var main := _new_main("")
	var player := _player(main)
	var enemy := (main.get_node("EnemySpawner") as EnemySpawner).spawn_at(Vector2(300, 300))
	assert_not_null(enemy)
	(enemy.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	var gems := get_tree().get_nodes_in_group(&"xp_gems")
	assert_eq(gems.size(), 1)
	var value := (gems[0] as XpGem).value
	assert_gt(value, 0)
	player.global_position = (gems[0] as XpGem).global_position
	await wait_physics_frames(4)
	assert_eq(main.profile.total_xp, value)


func test_level_up_is_saved_to_disk_immediately() -> void:
	var main := _new_main(_path())
	_player(main).progress.add_xp(30)
	assert_eq(SaveGame.load_profile(_path()).total_xp, 30)
	assert_eq(SaveGame.load_profile(_path()).level(_track), 2)


func test_level_up_shows_the_toast() -> void:
	var main := _new_main("")
	_player(main).progress.add_xp(30)
	var toast := main.get_node("Hud/LevelToast") as LevelToast
	assert_true(toast.is_showing())
	assert_string_contains(toast.text, "Level 2!")


func test_death_saves_the_profile_and_shows_the_summary() -> void:
	var main := _new_main(_path())
	_player(main).progress.add_xp(20)
	assert_false(FileAccess.file_exists(_path()), "20 XP is no level-up, so nothing is saved yet")
	(_player(main).get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_eq(SaveGame.load_profile(_path()).total_xp, 20)
	assert_eq((main.get_node("DeathScreen") as DeathScreen).summary_text(), "+20 XP this run, level 1")


func test_random_buff_reward_mid_run_changes_nothing_until_next_run() -> void:
	var main := _new_main("")
	_player(main).progress.add_xp(_track.xp_for_level(7))
	assert_eq(_stack_total(_player(main).loadout.slots[0].data), 0)
	var toast := main.get_node("Hud/LevelToast") as LevelToast
	assert_string_contains(toast.text, "Level 7!")
	assert_string_contains(toast.text, "Next run")


func test_owed_chosen_buff_opens_the_pick_screen_before_the_run_and_applies_after_choosing() -> void:
	_save_at_level(12)
	var main := _new_main(_path())
	var screen := main.get_node("BuffPickScreen") as BuffPickScreen
	watch_signals(screen)
	assert_true(screen.is_open())
	assert_gte(screen.option_count(), 4)
	screen.choose(0)
	assert_false(screen.is_open())
	var picked := get_signal_parameters(screen, "chosen")[0] as ScrollData
	var spell := _player(main).loadout.slots[0].data
	assert_eq(_stack_total(spell), 2, "the random buff of level 7 and the chosen one of level 12")
	assert_gte(int(spell.buff_stacks.get(picked.id, 0)), 1)
	_player(main).progress.add_xp(30)
	assert_false(FileAccess.get_file_as_string(_path()).contains("buff_picks"))


func test_unchosen_buff_is_asked_again_next_run() -> void:
	_save_at_level(12)
	var first := _new_main(_path())
	assert_true((first.get_node("BuffPickScreen") as BuffPickScreen).is_open())
	first.free()
	var second := _new_main(_path())
	assert_true((second.get_node("BuffPickScreen") as BuffPickScreen).is_open())


func test_random_buffs_are_rolled_every_run_and_never_saved() -> void:
	_save_at_level(7)
	var first := _new_main(_path())
	assert_eq(_stack_total(_player(first).loadout.slots[0].data), 1)
	_player(first).progress.add_xp(30)
	assert_false(FileAccess.get_file_as_string(_path()).contains("buff_picks"))
	first.free()
	var second := _new_main(_path())
	assert_eq(_stack_total(_player(second).loadout.slots[0].data), 1)


func test_chosen_buff_is_asked_every_run_even_after_choosing() -> void:
	_save_at_level(12)
	var first := _new_main(_path())
	(first.get_node("BuffPickScreen") as BuffPickScreen).choose(0)
	first.free()
	var second := _new_main(_path())
	assert_true((second.get_node("BuffPickScreen") as BuffPickScreen).is_open())


func test_run_start_toast_names_the_rolled_buff() -> void:
	_save_at_level(7)
	var main := _new_main(_path())
	var toast := main.get_node("Hud/LevelToast") as LevelToast
	assert_true(toast.is_showing())
	assert_string_contains(toast.text, "Starting spell gains")


func test_second_run_keeps_the_xp_from_the_first() -> void:
	var first := _new_main(_path())
	_player(first).progress.add_xp(30)
	first.free()
	var second := _new_main(_path())
	assert_eq(second.profile.total_xp, 30)
	assert_eq(_player(second).progress.level(), 2)
	assert_almost_eq(_speed(second), 97.2, 0.001)


func test_empty_save_path_never_creates_a_file() -> void:
	var existed_before := FileAccess.file_exists(SaveGame.DEFAULT_PATH)
	var main := _new_main("")
	_player(main).progress.add_xp(500)
	(_player(main).get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_eq(FileAccess.file_exists(SaveGame.DEFAULT_PATH), existed_before)
	assert_eq(DirAccess.get_files_at(ProjectSettings.globalize_path(_dir)).size(), 0)


func test_f12_gives_100_xp() -> void:
	var main := _new_main("")
	var event := InputEventAction.new()
	event.action = &"debug_give_xp"
	event.pressed = true
	main._unhandled_input(event)
	assert_eq(main.profile.total_xp, 100)
	assert_eq(_player(main).progress.level(), 3)


func test_spell_bar_shows_the_saved_slots_as_unlocked_at_run_start() -> void:
	_save_at_level(10)
	var main := _new_main(_path())
	var bar := main.get_node("Hud/SpellBar") as SpellBar
	for i in 5:
		assert_eq(bar.widgets[i].locked, i >= 3, "slot %d" % (i + 1))
