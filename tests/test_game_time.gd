extends GutTest


func before_each() -> void:
	GameTime.reset()


func after_each() -> void:
	get_tree().paused = false
	GameTime.reset()


func test_frozen_clock_does_not_advance() -> void:
	GameTime.freeze()
	var frozen := GameTime.now_msec()
	OS.delay_msec(40)
	assert_eq(GameTime.now_msec(), frozen)
	assert_true(GameTime.is_frozen())


func test_unfreeze_resumes_without_a_jump() -> void:
	GameTime.freeze()
	var frozen := GameTime.now_msec()
	OS.delay_msec(60)
	GameTime.unfreeze()
	assert_false(GameTime.is_frozen())
	assert_between(GameTime.now_msec() - frozen, 0, 25, "no jump for the 60 ms spent frozen")
	OS.delay_msec(30)
	assert_gte(GameTime.now_msec() - frozen, 30, "it runs again")


func test_freeze_is_idempotent() -> void:
	GameTime.freeze()
	var frozen := GameTime.now_msec()
	OS.delay_msec(30)
	GameTime.freeze()
	OS.delay_msec(30)
	assert_eq(GameTime.now_msec(), frozen)
	GameTime.unfreeze()
	GameTime.unfreeze()
	assert_between(GameTime.now_msec() - frozen, 0, 25)


func test_reset_clears_state() -> void:
	GameTime.freeze()
	OS.delay_msec(30)
	GameTime.reset()
	assert_false(GameTime.is_frozen())
	assert_between(GameTime.now_msec() - Time.get_ticks_msec(), -2, 2, "back in step with the real clock")


func test_game_pause_sets_the_tree_and_the_clock() -> void:
	GamePause.set_paused(get_tree(), true)
	var paused := get_tree().paused
	var frozen := GameTime.is_frozen()
	GamePause.set_paused(get_tree(), false)
	assert_true(paused)
	assert_true(frozen)
	assert_false(get_tree().paused)
	assert_false(GameTime.is_frozen())
