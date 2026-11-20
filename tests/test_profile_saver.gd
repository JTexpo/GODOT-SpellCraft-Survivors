extends GutTest

const ROOT := "res://.godot/save_tests"

var _dir: String
var _profile: PlayerProfile
var _saver: ProfileSaver


func before_each() -> void:
	_dir = "%s/saver_%s" % [ROOT, str(randi())]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_profile = PlayerProfile.new()
	_saver = ProfileSaver.new()
	_saver.interval = 10.0
	add_child_autofree(_saver)
	_saver.set_process(false)


func after_each() -> void:
	var absolute := ProjectSettings.globalize_path(_dir)
	for file in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute("%s/%s" % [absolute, file])
	DirAccess.remove_absolute(absolute)


func _path() -> String:
	return "%s/save.json" % _dir


func test_empty_path_never_writes() -> void:
	_saver.bind(_profile, "")
	_saver.mark_dirty()
	assert_false(_saver.is_dirty())
	assert_false(_saver.save_now())
	_saver.tick(100.0)
	assert_eq(DirAccess.get_files_at(ProjectSettings.globalize_path(_dir)).size(), 0)


func test_mark_dirty_then_tick_after_the_interval_saves() -> void:
	_saver.bind(_profile, _path())
	_profile.add_xp(12)
	_saver.mark_dirty()
	assert_true(_saver.is_dirty())
	_saver.tick(10.0)
	assert_false(_saver.is_dirty())
	assert_eq(SaveGame.load_profile(_path()).total_xp, 12)


func test_tick_before_the_interval_does_not_save() -> void:
	_saver.bind(_profile, _path())
	_saver.mark_dirty()
	_saver.tick(9.0)
	assert_true(_saver.is_dirty())
	assert_false(FileAccess.file_exists(_path()))


func test_a_clean_saver_never_saves_on_tick() -> void:
	_saver.bind(_profile, _path())
	_saver.tick(100.0)
	assert_false(FileAccess.file_exists(_path()))


func test_save_now_clears_dirty_only_on_success() -> void:
	_saver.bind(_profile, "%s/missing_folder/save.json" % _dir)
	_saver.mark_dirty()
	assert_false(_saver.save_now())
	assert_true(_saver.is_dirty())
	_saver.bind(_profile, _path())
	_saver.mark_dirty()
	assert_true(_saver.save_now())
	assert_false(_saver.is_dirty())


func test_close_notification_saves_when_dirty() -> void:
	_saver.bind(_profile, _path())
	_profile.add_xp(7)
	_saver.mark_dirty()
	_saver.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(SaveGame.load_profile(_path()).total_xp, 7)


func test_focus_loss_and_app_pause_save_when_dirty() -> void:
	_saver.bind(_profile, _path())
	_profile.add_xp(3)
	_saver.mark_dirty()
	_saver.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(SaveGame.load_profile(_path()).total_xp, 3)
	_profile.add_xp(4)
	_saver.mark_dirty()
	_saver.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(SaveGame.load_profile(_path()).total_xp, 7)
