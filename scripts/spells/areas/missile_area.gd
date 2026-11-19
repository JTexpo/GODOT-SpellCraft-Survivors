class_name MissileArea
extends AreaEffect
## The Missile Area: one projectile that flies in a straight line. Speed, range, size,
## damage, tint and how many enemies it can hit all come from the SpellData it is launched with.

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


func launch(spell: SpellData, origin: Vector2, launch_direction: Vector2, _target: Vector2) -> void:
	global_position = origin
	direction = launch_direction.normalized()
	_speed = spell.projectile_speed
	_life_left = spell.effective_range() / maxf(_speed, 0.001)
	_max_hits = spell.max_hits
	scale = Vector2.ONE * spell.effective_size()
	_body.color = spell.color
	_configure_hitbox(_hitbox, spell, _life_left + 1.0)
	_hitbox.max_hits = spell.max_hits


func _on_hit_landed(_target: HurtboxComponent) -> void:
	hits += 1
	if hits >= _max_hits:
		queue_free()
