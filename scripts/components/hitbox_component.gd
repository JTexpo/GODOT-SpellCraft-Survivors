class_name HitboxComponent
extends Area2D
## Deals damage to HurtboxComponents. Active hitboxes (monitoring = true) look for
## hurtboxes themselves. Passive ones are found by the hurtbox that watches them.

signal hit_landed(target: HurtboxComponent)

@export var damage: float = 10.0
@export var knockback: float = 0.0
## The attacker's element. The hurtbox applies the elemental multiplier when the hit lands.
@export var element: int = SpellData.NO_ELEMENT
## A spell's full elements and flags (several elements, vulnerability scale, ignore resistance).
## Null for attacks that only have `element`, such as enemies' contact hits.
var profile: AttackProfile = null
## Minimum seconds between hits on the same target. 0 means no limit.
@export var hit_cooldown: float = 0.0
## Stops after the first landed hit (same as max_hits = 1).
@export var one_shot: bool = false
## Stops after this many landed hits (piercing projectiles). 0 means no limit.
@export var max_hits: int = 0

var _last_hit_msec: Dictionary = {}
var _hits_landed: int = 0
var _finished: bool = false


func _ready() -> void:
	set_physics_process(monitoring)


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		var target := area as HurtboxComponent
		if target != null:
			try_hit(target)
			if _finished:
				break


func is_finished() -> bool:
	return _finished


func try_hit(target: HurtboxComponent, now_msec: int = GameTime.now_msec()) -> bool:
	if _finished:
		return false
	var id := target.get_instance_id()
	if hit_cooldown > 0.0 and _last_hit_msec.has(id):
		if now_msec - int(_last_hit_msec[id]) < int(hit_cooldown * 1000.0):
			return false
	if not target.receive_hit(damage, global_position, knockback, element, profile):
		return false
	_last_hit_msec[id] = now_msec
	_hits_landed += 1
	hit_landed.emit(target)
	if one_shot or (max_hits > 0 and _hits_landed >= max_hits):
		_finished = true
		set_deferred("monitoring", false)
		set_physics_process(false)
	return true
