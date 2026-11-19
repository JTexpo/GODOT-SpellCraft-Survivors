extends GutTest

const C := ScrollData.Category

var _inventory: ScrollInventory
var _panel: InventoryPanel


func _scroll(id: StringName, display: String, category: ScrollData.Category, rarity: ScrollData.Rarity) -> ScrollData:
	var scroll := ScrollData.new()
	scroll.id = id
	scroll.display_name = display
	scroll.category = category
	scroll.rarity = rarity
	return scroll


func before_each() -> void:
	_inventory = ScrollInventory.new()
	add_child_autofree(_inventory)
	_panel = load("res://scenes/ui/inventory_panel.tscn").instantiate() as InventoryPanel
	add_child_autofree(_panel)
	_panel.bind(_inventory)


func test_panel_starts_closed() -> void:
	assert_false(_panel.is_open())
	assert_false(_panel.visible)


func test_toggle_opens_and_closes() -> void:
	_panel.toggle()
	assert_true(_panel.is_open())
	_panel.toggle()
	assert_false(_panel.is_open())
	_panel.set_open(true)
	assert_true(_panel.visible)
	_panel.set_open(false)
	assert_false(_panel.visible)


func test_entries_group_by_category_with_counts() -> void:
	_inventory.add(_scroll(&"base_fire", "Fire", C.BASE, ScrollData.Rarity.COMMON), 3)
	_inventory.add(_scroll(&"area_line", "Line", C.AREA, ScrollData.Rarity.COMMON))
	_inventory.add(_scroll(&"buff_dv", "Double Vulnerability Damage", C.BUFF, ScrollData.Rarity.RARE), 2)
	assert_eq(_panel.entries(), [
		"Base", "Fire (Common) x3",
		"Area", "Line (Common) x1",
		"Buff", "Double Vulnerability Damage (Rare) x2",
	])


func test_empty_categories_show_a_dash() -> void:
	assert_eq(_panel.entries(), ["Base", "-", "Area", "-", "Buff", "-"])


func test_panel_updates_when_the_inventory_changes_while_open() -> void:
	_panel.set_open(true)
	var fire := _scroll(&"base_fire", "Fire", C.BASE, ScrollData.Rarity.UNCOMMON)
	_inventory.add(fire)
	assert_eq(_panel.entries()[1], "Fire (Uncommon) x1")
	assert_eq(_panel.row_count(), 1)
	_inventory.add(fire)
	assert_eq(_panel.entries()[1], "Fire (Uncommon) x2")


func test_removed_scrolls_leave_no_row() -> void:
	var fire := _scroll(&"base_fire", "Fire", C.BASE, ScrollData.Rarity.COMMON)
	_panel.set_open(true)
	_inventory.add(fire)
	_inventory.remove(fire)
	assert_eq(_panel.entries(), ["Base", "-", "Area", "-", "Buff", "-"])
	assert_eq(_panel.row_count(), 0)
