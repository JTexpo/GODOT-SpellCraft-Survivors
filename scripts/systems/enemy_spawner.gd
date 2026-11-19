class_name EnemySpawner
extends Node
## Spawns enemies on a ring just outside the player's view, inside the arena.

signal enemy_damaged(position: Vector2, amount: float, effect: int)

const MAX_SPAWNS_PER_TICK := 4
const SPAWN_ANGLE_ATTEMPTS := 8

@export var config: SpawnConfig
@export var arena_bounds: Rect2 = Rect2(0, 0, 960, 540)
@export var view_size: Vector2 = Vector2(480, 270)

var rng := RandomNumberGenerator.new()
var alive: int = 0
## Where enemies are added. Defaults to this node's parent.
var spawn_root: Node

var _time_since_spawn: float = 0.0


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if config == null:
		return
	var interval := maxf(config.interval, 0.01)
	_time_since_spawn += delta
	var budget := MAX_SPAWNS_PER_TICK
	while _time_since_spawn >= interval and budget > 0:
		_time_since_spawn -= interval
		budget -= 1
		if try_spawn() == null:
			_time_since_spawn = 0.0
			return


## Picks from the pool by spawn_weight. Null when there is no pool or every weight is zero.
func pick_enemy_data() -> EnemyData:
	if config == null:
		return null
	var total := 0.0
	for data in config.enemy_pool:
		total += maxf(data.spawn_weight, 0.0)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for data in config.enemy_pool:
		roll -= maxf(data.spawn_weight, 0.0)
		if roll < 0.0:
			return data
	return config.enemy_pool.back()


func try_spawn() -> Enemy:
	if config == null or alive >= config.max_alive:
		return null
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return null
	var position := spawn_position(player.global_position)
	if position == Vector2.INF:
		return null
	return spawn_at(position)


func spawn_at(position: Vector2) -> Enemy:
	var data := pick_enemy_data()
	if data == null:
		return null
	var enemy := config.enemy_scene.instantiate() as Enemy
	enemy.setup(data, arena_bounds, rng)
	var root := spawn_root if spawn_root != null else get_parent()
	root.add_child(enemy)
	enemy.global_position = position
	alive += 1
	enemy.died.connect(_on_enemy_died)
	enemy.damaged.connect(enemy_damaged.emit)
	return enemy


## A point just outside what the camera can see, clamped into the arena.
## The camera stops scrolling at the arena edge, so the visible area is the player-centred view
## pushed back inside the arena. Returns Vector2.INF when no valid point is found.
func spawn_position(player_position: Vector2) -> Vector2:
	var half_view := view_size / 2.0
	var lowest := arena_bounds.position + half_view
	var highest := (arena_bounds.end - half_view).max(lowest)
	var view_center := player_position.clamp(lowest, highest)
	var view_rect := Rect2(view_center - half_view, view_size)
	var ring_half := half_view + Vector2(config.spawn_margin, config.spawn_margin)
	for attempt in SPAWN_ANGLE_ATTEMPTS:
		var direction := Vector2.from_angle(rng.randf_range(0.0, TAU))
		var scale := maxf(absf(direction.x) / ring_half.x, absf(direction.y) / ring_half.y)
		var point := view_center + direction / scale
		point = point.clamp(arena_bounds.position, arena_bounds.end)
		if not _inside_inclusive(view_rect, point):
			return point
	return Vector2.INF


func _inside_inclusive(rect: Rect2, point: Vector2) -> bool:
	return point.x >= rect.position.x and point.y >= rect.position.y \
		and point.x <= rect.end.x and point.y <= rect.end.y


func _on_enemy_died(_enemy: Enemy) -> void:
	alive = maxi(alive - 1, 0)
