class_name HurtboxComponent
extends Area2D
## Receives hits for an entity and forwards them to its HealthComponent.
## Passive hurtboxes (monitoring = false) cost nothing per frame.

signal hit_received(damage: float, source_position: Vector2, knockback: float)

@export var health: HealthComponent
## Player-wide window after a landed hit during which further hits are ignored.
@export var invulnerability_time: float = 0.0

var _invulnerable_left: float = 0.0


func _ready() -> void:
	set_process(false)
	set_physics_process(monitoring)


func _process(delta: float) -> void:
	_invulnerable_left -= delta
	if _invulnerable_left <= 0.0:
		_invulnerable_left = 0.0
		set_process(false)


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		var hitbox := area as HitboxComponent
		if hitbox != null:
			hitbox.try_hit(self)


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func receive_hit(damage: float, source_position: Vector2, knockback: float = 0.0) -> bool:
	if health == null or health.is_dead() or is_invulnerable():
		return false
	var dealt := DamageSystem.calculate(damage)
	health.take_damage(dealt)
	hit_received.emit(dealt, source_position, knockback)
	if invulnerability_time > 0.0:
		_invulnerable_left = invulnerability_time
		set_process(true)
	return true
