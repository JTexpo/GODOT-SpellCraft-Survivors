class_name HurtboxComponent
extends Area2D
## Receives hits for an entity and forwards them to its HealthComponent.
## Passive hurtboxes (monitoring = false) cost nothing per frame.

## `effect` is an ElementTable.Effect: how the attacker's element fared against this one.
signal hit_received(damage: float, source_position: Vector2, knockback: float, effect: int)

@export var health: HealthComponent
## This target's element (none by default). Enemies take theirs from EnemyData, and equipment
## can give the player one later.
@export var element: int = SpellData.NO_ELEMENT
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


func receive_hit(
	damage: float,
	source_position: Vector2,
	knockback: float = 0.0,
	attacker_element: int = SpellData.NO_ELEMENT,
) -> bool:
	if health == null or health.is_dead() or is_invulnerable():
		return false
	var dealt := DamageSystem.calculate(damage, attacker_element, element)
	var effect := DamageSystem.effect(attacker_element, element)
	health.take_damage(dealt)
	hit_received.emit(dealt, source_position, knockback, effect)
	if invulnerability_time > 0.0:
		_invulnerable_left = invulnerability_time
		set_process(true)
	return true
