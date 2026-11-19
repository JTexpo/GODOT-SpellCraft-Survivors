extends GutTest

const C := ScrollData.Category

var _inventory: ScrollInventory
var _fire: ScrollData
var _thunder: ScrollData
var _line: ScrollData


func _scroll(id: StringName, category: ScrollData.Category) -> ScrollData:
	var scroll := ScrollData.new()
	scroll.id = id
	scroll.display_name = str(id)
	scroll.category = category
	return scroll


func before_each() -> void:
	_inventory = ScrollInventory.new()
	add_child_autofree(_inventory)
	_fire = _scroll(&"base_fire", C.BASE)
	_thunder = _scroll(&"base_thunder", C.BASE)
	_line = _scroll(&"area_line", C.AREA)


func test_add_stacks_identical_scrolls() -> void:
	_inventory.add(_fire)
	_inventory.add(_fire)
	_inventory.add(_thunder)
	assert_eq(_inventory.count(_fire), 2)
	assert_eq(_inventory.count(_thunder), 1)
	assert_eq(_inventory.total_count(), 3)


func test_stacking_is_by_id() -> void:
	_inventory.add(_fire)
	_inventory.add(_scroll(&"base_fire", C.BASE))
	assert_eq(_inventory.count(_fire), 2)
	assert_eq(_inventory.by_category(C.BASE).size(), 1)


func test_add_ignores_null_and_non_positive_amounts() -> void:
	watch_signals(_inventory)
	_inventory.add(null)
	_inventory.add(_fire, 0)
	_inventory.add(_fire, -3)
	assert_eq(_inventory.total_count(), 0)
	assert_signal_not_emitted(_inventory, "changed")


func test_remove_is_all_or_nothing() -> void:
	_inventory.add(_fire, 2)
	assert_false(_inventory.remove(_fire, 3))
	assert_eq(_inventory.count(_fire), 2)
	assert_false(_inventory.remove(_fire, 0))
	assert_false(_inventory.remove(null))
	assert_false(_inventory.remove(_thunder))
	assert_true(_inventory.remove(_fire, 2))
	assert_eq(_inventory.count(_fire), 0)


func test_removing_the_last_one_leaves_no_row() -> void:
	_inventory.add(_fire)
	_inventory.remove(_fire)
	assert_eq(_inventory.by_category(C.BASE), [])
	assert_false(_inventory.has(_fire))
	assert_eq(_inventory.total_count(), 0)


func test_by_category_groups_and_keeps_first_collected_order() -> void:
	_inventory.add(_thunder)
	_inventory.add(_fire)
	_inventory.add(_line)
	_inventory.add(_thunder)
	assert_eq(_inventory.by_category(C.BASE), [_thunder, _fire])
	assert_eq(_inventory.by_category(C.AREA), [_line])
	assert_eq(_inventory.by_category(C.BUFF), [])


func test_changed_emits_on_add_and_remove_only_when_something_changed() -> void:
	watch_signals(_inventory)
	_inventory.add(_fire, 2)
	assert_signal_emit_count(_inventory, "changed", 1)
	assert_signal_emitted_with_parameters(_inventory, "changed", [_fire])
	_inventory.remove(_fire, 5)
	assert_signal_emit_count(_inventory, "changed", 1)
	_inventory.remove(_fire, 1)
	assert_signal_emit_count(_inventory, "changed", 2)


func test_has_with_amounts() -> void:
	_inventory.add(_fire, 2)
	assert_true(_inventory.has(_fire))
	assert_true(_inventory.has(_fire, 2))
	assert_false(_inventory.has(_fire, 3))
	assert_false(_inventory.has(_thunder))
