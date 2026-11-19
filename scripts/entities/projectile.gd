class_name Projectile
extends Node2D
## TEMPORARY (Sprint 1): straight-line stand-in projectile. The hitbox/damage plumbing stays,
## this scene is expected to go when Sprint 2's spells arrive.

var direction: Vector2 = Vector2.RIGHT

var _speed: float = 0.0
var _life_left: float = 0.0

@onready var _hitbox: HitboxComponent = $Hitbox


func _ready() -> void:
	_hitbox.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	position += direction * _speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


## Call after the projectile is in the tree.
func launch(launch_direction: Vector2, data: AttackData) -> void:
	direction = launch_direction.normalized()
	_speed = data.projectile_speed
	_life_left = data.lifetime
	_hitbox.damage = data.damage
	_hitbox.knockback = data.knockback


func _on_hit_landed(_target: HurtboxComponent) -> void:
	queue_free()
