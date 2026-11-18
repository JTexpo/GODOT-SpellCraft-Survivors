extends GutTest


func test_missing_path_returns_error_and_keeps_scene() -> void:
	var before := get_tree().current_scene
	var result := SceneSwitcher.change_to(get_tree(), "res://nope.tscn")
	assert_eq(result, ERR_FILE_NOT_FOUND)
	assert_eq(get_tree().current_scene, before)


func test_empty_path_returns_error() -> void:
	assert_eq(SceneSwitcher.change_to(get_tree(), ""), ERR_FILE_NOT_FOUND)
