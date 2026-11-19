extends GutTest

const ENEMY_DIR := "res://resources/enemies/"
const ELEMENT_ENEMIES := {
	"fire_enemy": SpellData.Element.FIRE,
	"thunder_enemy": SpellData.Element.THUNDER,
	"land_enemy": SpellData.Element.LAND,
	"sea_enemy": SpellData.Element.SEA,
}
const ENEMY_FILES := ["basic_enemy", "fire_enemy", "thunder_enemy", "land_enemy", "sea_enemy"]

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11


func _scroll(id: StringName) -> ScrollData:
	var scroll := ScrollData.new()
	scroll.id = id
	return scroll


func _entry(scroll: ScrollData, weight: float) -> DropEntry:
	var entry := DropEntry.new()
	entry.scroll = scroll
	entry.weight = weight
	return entry


func _table(chance: float, entries: Array[DropEntry]) -> DropTable:
	var table := DropTable.new()
	table.drop_chance = chance
	table.entries = entries
	return table


func _full_chance_table(enemy_file: String) -> DropTable:
	var data := load(ENEMY_DIR + enemy_file + ".tres") as EnemyData
	var table := data.drop_table.duplicate() as DropTable
	table.drop_chance = 1.0
	return table


func test_chance_zero_never_drops_and_one_always_drops() -> void:
	var good := _scroll(&"a")
	var never := _table(0.0, [_entry(good, 1.0)] as Array[DropEntry])
	var always := _table(1.0, [_entry(good, 1.0)] as Array[DropEntry])
	for i in 200:
		assert_null(never.roll(_rng))
		assert_eq(always.roll(_rng), good)


func test_weights_are_respected() -> void:
	var light := _scroll(&"light")
	var heavy := _scroll(&"heavy")
	var table := _table(1.0, [_entry(light, 1.0), _entry(heavy, 3.0)] as Array[DropEntry])
	var counts := {light: 0, heavy: 0}
	for i in 2000:
		counts[table.roll(_rng)] += 1
	assert_gt(counts[heavy], counts[light] * 2)


func test_unpickable_entries_are_never_picked() -> void:
	var good := _scroll(&"good")
	var scroll_less := DropEntry.new()
	var entries: Array[DropEntry] = [
		null, scroll_less, _entry(_scroll(&"zero"), 0.0), _entry(_scroll(&"negative"), -2.0), _entry(good, 1.0),
	]
	var table := _table(1.0, entries)
	for i in 300:
		assert_eq(table.roll(_rng), good)


func test_empty_and_all_unpickable_tables_return_null() -> void:
	assert_null(_table(1.0, [] as Array[DropEntry]).roll(_rng))
	var junk: Array[DropEntry] = [null, DropEntry.new(), _entry(_scroll(&"zero"), 0.0)]
	assert_null(_table(1.0, junk).roll(_rng))


func test_every_enemy_has_a_themed_table() -> void:
	for file in ELEMENT_ENEMIES:
		var own: int = ELEMENT_ENEMIES[file]
		var table := _full_chance_table(file)
		var base_total := 0
		var own_total := 0
		var all_total := 6000
		for i in all_total:
			var scroll := table.roll(_rng)
			if scroll.category == ScrollData.Category.BASE:
				base_total += 1
				if scroll.element == own:
					own_total += 1
		var share := float(own_total) / base_total
		assert_between(share, 0.75, 0.85, "%s own share of Base drops" % file)
		assert_lt(own_total, base_total, "%s is never guaranteed" % file)
		assert_between(float(own_total) / all_total, 0.35, 0.55, "%s own share of all drops" % file)


func test_the_plain_enemy_favours_no_element() -> void:
	var table := _full_chance_table("basic_enemy")
	var counts := {}
	var base_total := 0
	for i in 6000:
		var scroll := table.roll(_rng)
		if scroll.category == ScrollData.Category.BASE:
			base_total += 1
			counts[scroll.element] = counts.get(scroll.element, 0) + 1
	assert_eq(counts.size(), 4)
	for element in counts:
		assert_between(float(counts[element]) / base_total, 0.20, 0.30)


func test_every_catalog_scroll_can_drop() -> void:
	var seen := {}
	for file in ENEMY_FILES:
		var data := load(ENEMY_DIR + file + ".tres") as EnemyData
		for entry in data.drop_table.entries:
			seen[entry.scroll.id] = true
	assert_eq(seen.size(), 15)


func test_drop_chance_is_six_percent_everywhere() -> void:
	for file in ENEMY_FILES:
		var data := load(ENEMY_DIR + file + ".tres") as EnemyData
		assert_eq(data.drop_table.drop_chance, 0.06, file)
