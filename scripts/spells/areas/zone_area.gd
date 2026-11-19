class_name ZoneArea
extends AreaEffect
## The Area Area: a damage zone dropped where the player points, held within the spell's range.
## Radius is the spell's effective size. It lasts `duration` seconds and hits each enemy inside
## once per `tick_interval`.

const OUTLINE_POINTS := 24
const VISUAL_ALPHA := 0.35

var _life_left: float = 0.0

@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _shape: CollisionShape2D = $Hitbox/Shape
@onready var _visual: Polygon2D = $Visual


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


func launch(spell: SpellData, origin: Vector2, _direction: Vector2, target: Vector2) -> void:
	global_position = spell.clamp_target(origin, target)
	var radius := spell.effective_size()
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle
	var outline := PackedVector2Array()
	for i in OUTLINE_POINTS:
		outline.append(Vector2.from_angle(TAU * i / OUTLINE_POINTS) * radius)
	_visual.polygon = outline
	var tint := spell.color
	tint.a = VISUAL_ALPHA
	_visual.color = tint
	_life_left = spell.area_data.duration
	var tick := spell.area_data.tick_interval
	# With no tick interval, each enemy is hit once for the zone's whole life.
	_configure_hitbox(_hitbox, spell, tick if tick > 0.0 else _life_left + 1.0)
