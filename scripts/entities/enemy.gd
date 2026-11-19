class_name Enemy
extends Node2D
## A light enemy: no physics body, moved by position. Hits are detected through
## its passive hurtbox and contact hitbox.

signal died(enemy: Enemy)

@export var data: EnemyData

var speed: float = 0.0
var target_offset: Vector2 = Vector2.ZERO

var _bounds: Rect2 = Rect2(0, 0, 960, 540)
var _dead: bool = false

@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $HurtboxComponent
@onready var _hitbox: HitboxComponent = $ContactHitbox
@onready var _knockback: KnockbackComponent = $KnockbackComponent
@onready var _flash: HitFlashComponent = $HitFlashComponent


func _ready() -> void:
	_hurtbox.hit_received.connect(_on_hit_received)
	_health.died.connect(_on_died)
	if data != null:
		if speed == 0.0:
			speed = data.speed
		_apply_data()


func _physics_process(delta: float) -> void:
	var velocity := direction_to_target() * speed + _knockback.update(delta)
	position += velocity * delta
	position = position.clamp(_bounds.position, _bounds.end)


## `arena_bounds` is in the parent's coordinate space.
func setup(enemy_data: EnemyData, arena_bounds: Rect2, rng: RandomNumberGenerator) -> void:
	data = enemy_data
	_bounds = arena_bounds
	speed = data.speed * rng.randf_range(1.0 - data.speed_variation, 1.0 + data.speed_variation)
	var angle := rng.randf_range(0.0, TAU)
	target_offset = Vector2.from_angle(angle) * data.offset_radius * sqrt(rng.randf())
	if is_node_ready():
		_apply_data()


## Heads for the player plus a random offset that spreads the horde out while it is far away.
## The offset fades out as the enemy closes in, so it always ends up touching the player.
func direction_to_target() -> Vector2:
	var target := get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return Vector2.ZERO
	var spread := 1.0
	if data != null and data.offset_radius > 0.0:
		var distance := global_position.distance_to(target.global_position)
		spread = clampf((distance - data.offset_radius) / data.offset_radius, 0.0, 1.0)
	var to_target := (target.global_position + target_offset * spread) - global_position
	if to_target.length() < 1.0:
		return Vector2.ZERO
	return to_target.normalized()


func _apply_data() -> void:
	_health.set_max_health(data.max_health)
	_hitbox.damage = data.contact_damage
	_hitbox.hit_cooldown = data.contact_cooldown
	_hitbox.knockback = data.contact_knockback


func _on_hit_received(_damage: float, source_position: Vector2, knockback: float) -> void:
	_knockback.apply_impulse(global_position - source_position, knockback)
	_flash.flash()


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	_hurtbox.set_deferred("monitorable", false)
	_hitbox.set_deferred("monitorable", false)
	set_physics_process(false)
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)
