class_name KnockbackComponent
extends Node

## Speed lost per second while a knockback is active.
@export var decay: float = 600.0

var velocity: Vector2 = Vector2.ZERO


func apply_impulse(direction: Vector2, strength: float) -> void:
	if direction == Vector2.ZERO or strength <= 0.0:
		return
	velocity += direction.normalized() * strength


## Returns the knockback velocity to use this step, then decays it.
func update(delta: float) -> Vector2:
	var current := velocity
	velocity = velocity.move_toward(Vector2.ZERO, decay * delta)
	return current
