class_name PickupCollector
extends Area2D
## The player's one active pickup detector. Scrolls on the ground are passive, so this is the
## only node doing overlap work. Collects automatically, and a dead player collects nothing.

signal collected(scroll: ScrollData)

@export var inventory: ScrollInventory
@export var health: HealthComponent


func _physics_process(_delta: float) -> void:
	if inventory == null or (health != null and health.is_dead()):
		return
	for area in get_overlapping_areas():
		var pickup := area as ScrollPickup
		if pickup == null:
			continue
		var scroll := pickup.collect()
		if scroll != null:
			inventory.add(scroll)
			collected.emit(scroll)
