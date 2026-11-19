class_name DropTable
extends Resource
## What an enemy can drop when it dies: a chance that anything drops, then a weighted pick.

@export_range(0.0, 1.0) var drop_chance: float = 0.06
@export var entries: Array[DropEntry] = []


## Returns the scroll that drops, or null for no drop. Empty slots, entries without a scroll and
## weights at or below zero are never picked.
func roll(rng: RandomNumberGenerator) -> ScrollData:
	if drop_chance <= 0.0:
		return null
	var total := 0.0
	var last_pickable: DropEntry = null
	for entry in entries:
		if _pickable(entry):
			total += entry.weight
			last_pickable = entry
	if last_pickable == null:
		return null
	if drop_chance < 1.0 and rng.randf() >= drop_chance:
		return null
	var pick := rng.randf() * total
	for entry in entries:
		if not _pickable(entry):
			continue
		pick -= entry.weight
		if pick < 0.0:
			return entry.scroll
	return last_pickable.scroll


func _pickable(entry: DropEntry) -> bool:
	return entry != null and entry.scroll != null and entry.weight > 0.0
