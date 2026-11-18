extends GutTest


func test_resolution_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 480)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 270)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0)
