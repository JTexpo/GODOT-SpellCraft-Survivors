extends GutTest


func _make() -> Array:
	var body := ColorRect.new()
	add_child_autofree(body)
	var flash := HitFlashComponent.new()
	flash.target = body
	add_child_autofree(flash)
	return [flash, body]


func test_flash_sets_color_then_restores() -> void:
	var parts := _make()
	var flash: HitFlashComponent = parts[0]
	var body: ColorRect = parts[1]
	flash.flash()
	assert_true(flash.is_flashing)
	assert_eq(body.modulate, flash.flash_color)
	flash._process(0.2)
	assert_eq(body.modulate, Color.WHITE)
	assert_false(flash.is_flashing)


func test_flash_without_target_does_nothing() -> void:
	var flash := HitFlashComponent.new()
	add_child_autofree(flash)
	flash.flash()
	assert_false(flash.is_flashing)
