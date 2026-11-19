class_name HitboxComponent
extends Area2D
## Deals damage to HurtboxComponents. Active hitboxes (monitoring = true) look for
## hurtboxes themselves. Passive ones are found by the hurtbox that watches them.

signal hit_landed(target: HurtboxComponent)

@export var damage: float = 10.0
@export var knockback: float = 0.0
## Minimum seconds between hits on the same target. 0 means no limit.
@export var hit_cooldown: float = 0.0
## Stops after the first landed hit (projectiles).
@export var one_shot: bool = false

var _last_hit_msec: Dictionary = {}


func _ready() -> void:
	set_physics_process(monitoring)


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		var target := area as HurtboxComponent
		if target != null and try_hit(target) and one_shot:
			break


func try_hit(target: HurtboxComponent, now_msec: int = Time.get_ticks_msec()) -> bool:
	var id := target.get_instance_id()
	if hit_cooldown > 0.0 and _last_hit_msec.has(id):
		if now_msec - int(_last_hit_msec[id]) < int(hit_cooldown * 1000.0):
			return false
	if not target.receive_hit(damage, global_position, knockback):
		return false
	_last_hit_msec[id] = now_msec
	hit_landed.emit(target)
	if one_shot:
		set_deferred("monitoring", false)
		set_physics_process(false)
	return true
