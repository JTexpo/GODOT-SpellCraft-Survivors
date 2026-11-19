class_name AttackComponent
extends Node
## TEMPORARY (Sprint 1): fires the stand-in projectile on a cooldown.

@export var data: AttackData
## Where projectiles are added. Defaults to the owner's parent.
var projectile_root: Node

var _cooldown_left: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left = 0.0
		set_process(false)


func try_fire(origin: Vector2, direction: Vector2) -> Node2D:
	if data == null or data.projectile_scene == null or direction == Vector2.ZERO:
		return null
	if _cooldown_left > 0.0:
		return null
	var root := projectile_root if projectile_root != null else get_parent().get_parent()
	var projectile := data.projectile_scene.instantiate() as Projectile
	root.add_child(projectile)
	projectile.global_position = origin
	projectile.launch(direction, data)
	_cooldown_left = data.cooldown
	set_process(true)
	return projectile
