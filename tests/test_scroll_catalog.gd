extends GutTest

const C := ScrollData.Category
const R := ScrollData.Rarity
const T := AreaData.AreaType
const E := SpellData.Element
const PALE := Color(0.85, 0.85, 0.9)
const PURPLE := Color(0.75, 0.4, 0.9)
# file, id, display name, category, rarity, colour, payload (element, area type or buff id)
const SCROLLS := [
	["base/fire", &"base_fire", "Fire", C.BASE, R.COMMON, Color(1, 0.45, 0.1), E.FIRE],
	["base/thunder", &"base_thunder", "Thunder", C.BASE, R.COMMON, Color(1, 0.9, 0.2), E.THUNDER],
	["base/land", &"base_land", "Land", C.BASE, R.COMMON, Color(0.6, 0.4, 0.2), E.LAND],
	["base/sea", &"base_sea", "Sea", C.BASE, R.COMMON, Color(0.2, 0.55, 1), E.SEA],
	["area/line", &"area_line", "Line", C.AREA, R.COMMON, PALE, T.LINE],
	["area/cone", &"area_cone", "Cone", C.AREA, R.COMMON, PALE, T.CONE],
	["area/area", &"area_area", "Area", C.AREA, R.UNCOMMON, PALE, T.AREA],
	["area/missile", &"area_missile", "Missile", C.AREA, R.COMMON, PALE, T.MISSILE],
	["area/wave", &"area_wave", "Wave", C.AREA, R.UNCOMMON, PALE, T.WAVE],
	["buff/max_mana", &"buff_max_mana", "Increased Max Mana", C.BUFF, R.UNCOMMON, PURPLE, &"max_mana"],
	["buff/damage", &"buff_damage", "Increased Damage", C.BUFF, R.UNCOMMON, PURPLE, &"damage"],
	["buff/double_vulnerability", &"buff_double_vulnerability", "Double Vulnerability Damage", C.BUFF, R.RARE, PURPLE, &"double_vulnerability"],
	["buff/ignore_resistance", &"buff_ignore_resistance", "Ignore Resistance", C.BUFF, R.RARE, PURPLE, &"ignore_resistance"],
	["buff/duplicate_area", &"buff_duplicate_area", "Duplicate Area", C.BUFF, R.RARE, PURPLE, &"duplicate_area"],
	["buff/additional_base", &"buff_additional_base", "Additional Base", C.BUFF, R.RARE, PURPLE, &"additional_base"],
]


func _load(file: String) -> ScrollData:
	return load("res://resources/scrolls/%s.tres" % file) as ScrollData


func test_all_fifteen_scrolls_match_the_catalog() -> void:
	assert_eq(SCROLLS.size(), 15)
	for row in SCROLLS:
		var scroll := _load(row[0])
		assert_not_null(scroll, row[0])
		assert_eq(scroll.id, row[1], row[0])
		assert_eq(scroll.display_name, row[2], row[0])
		assert_eq(scroll.category, row[3], row[0])
		assert_eq(scroll.rarity, row[4], row[0])
		assert_eq(scroll.color, row[5], row[0])
		assert_false(scroll.description.is_empty(), row[0])
		match scroll.category:
			C.BASE:
				assert_eq(scroll.element, row[6], row[0])
				assert_null(scroll.area_data, row[0])
				assert_eq(scroll.buff_id, &"", row[0])
			C.AREA:
				assert_not_null(scroll.area_data, row[0])
				assert_eq(scroll.area_data.type, row[6], row[0])
				assert_eq(scroll.element, SpellData.NO_ELEMENT, row[0])
			C.BUFF:
				assert_eq(scroll.buff_id, row[6], row[0])
				assert_null(scroll.area_data, row[0])
				assert_eq(scroll.element, SpellData.NO_ELEMENT, row[0])


func test_ids_are_unique() -> void:
	var seen := {}
	for row in SCROLLS:
		assert_false(seen.has(row[1]), "duplicate id %s" % row[1])
		seen[row[1]] = true
