class_name PickupCollector
extends Area2D
## The player's one active pickup detector. Scrolls and XP gems on the ground are passive, so this is
## the only node doing overlap work. Collects automatically, and a dead player collects nothing.

signal collected(scroll: ScrollData)
signal xp_collected(amount: int)
signal gold_collected(amount: int)

@export var inventory: ScrollInventory
@export var health: HealthComponent


func _physics_process(_delta: float) -> void:
	if health != null and health.is_dead():
		return
	for area in get_overlapping_areas():
		if area is ValueGem:
			var gem := area as ValueGem
			var amount := gem.collect()
			if amount > 0:
				if gem.kind == ValueGem.Kind.GOLD:
					gold_collected.emit(amount)
				else:
					xp_collected.emit(amount)
		elif area is ScrollPickup and inventory != null:
			var scroll := (area as ScrollPickup).collect()
			if scroll != null:
				inventory.add(scroll)
				collected.emit(scroll)
