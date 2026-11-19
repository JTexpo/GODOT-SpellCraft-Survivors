class_name SpellProjectile
extends Node2D
## A spell's straight-line missile. Speed, damage, tint and how many enemies it can hit all
## come from the SpellData it was launched with.

var direction: Vector2 = Vector2.RIGHT
var hits: int = 0

var _speed: float = 0.0
var _life_left: float = 0.0
var _max_hits: int = 1

@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _body: ColorRect = $Body


func _ready() -> void:
	_hitbox.hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	position += direction * _speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


## Call after the projectile is in the tree.
func launch(launch_direction: Vector2, spell: SpellData) -> void:
	direction = launch_direction.normalized()
	_speed = spell.projectile_speed
	_life_left = spell.projectile_lifetime
	_max_hits = spell.max_hits
	_body.color = spell.color
	_hitbox.damage = DamageSystem.calculate(spell.damage, spell.primary_element())
	_hitbox.knockback = spell.knockback
	_hitbox.max_hits = spell.max_hits
	# Longer than its own lifetime, so one projectile never hits the same enemy twice.
	_hitbox.hit_cooldown = spell.projectile_lifetime + 1.0


func _on_hit_landed(_target: HurtboxComponent) -> void:
	hits += 1
	if hits >= _max_hits:
		queue_free()
