extends GutTest

const TMP_PATH := "user://test_spell_data.tres"


func after_each() -> void:
	if FileAccess.file_exists(TMP_PATH):
		DirAccess.remove_absolute(TMP_PATH)


func test_spell_data_defaults() -> void:
	var spell := SpellData.new()
	assert_eq(spell.elements.size(), 0)
	assert_null(spell.area_data)
	assert_eq(spell.range_scale, 1.0)
	assert_eq(spell.size_scale, 1.0)


func test_scroll_data_defaults() -> void:
	var scroll := ScrollData.new()
	assert_eq(scroll.category, ScrollData.Category.BASE)


func test_resources_round_trip() -> void:
	var spell := SpellData.new()
	spell.id = &"fire_bolt"
	spell.elements = [SpellData.Element.FIRE, SpellData.Element.THUNDER]
	spell.range_scale = 1.5
	spell.size_scale = 0.75
	assert_eq(ResourceSaver.save(spell, TMP_PATH), OK)
	var loaded := ResourceLoader.load(TMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SpellData
	assert_not_null(loaded)
	assert_eq(loaded.id, &"fire_bolt")
	assert_eq(loaded.elements, [SpellData.Element.FIRE, SpellData.Element.THUNDER])
	assert_eq(loaded.range_scale, 1.5)
	assert_eq(loaded.size_scale, 0.75)
