class_name ScrollInventory
extends Node
## The scrolls the player has collected this run. Identical scrolls stack by id. It knows
## nothing about pickups or any UI, so the Lectern can read and consume it later.

signal changed(scroll: ScrollData)

## id -> {"scroll": ScrollData, "count": int}, in the order scrolls were first collected.
var _rows: Dictionary = {}


func add(scroll: ScrollData, amount: int = 1) -> void:
	if scroll == null or amount <= 0:
		return
	if _rows.has(scroll.id):
		_rows[scroll.id]["count"] += amount
	else:
		_rows[scroll.id] = {"scroll": scroll, "count": amount}
	changed.emit(scroll)


## All or nothing: false, with nothing removed, if fewer than `amount` are owned.
func remove(scroll: ScrollData, amount: int = 1) -> bool:
	if scroll == null or amount <= 0 or not has(scroll, amount):
		return false
	_rows[scroll.id]["count"] -= amount
	if _rows[scroll.id]["count"] <= 0:
		_rows.erase(scroll.id)
	changed.emit(scroll)
	return true


func count(scroll: ScrollData) -> int:
	if scroll == null or not _rows.has(scroll.id):
		return 0
	return _rows[scroll.id]["count"]


func has(scroll: ScrollData, amount: int = 1) -> bool:
	return count(scroll) >= amount


func by_category(category: ScrollData.Category) -> Array[ScrollData]:
	var scrolls: Array[ScrollData] = []
	for row in _rows.values():
		if row["scroll"].category == category:
			scrolls.append(row["scroll"])
	return scrolls


func total_count() -> int:
	var total := 0
	for row in _rows.values():
		total += row["count"]
	return total
