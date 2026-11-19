extends GutTest

var _root: Node2D
var _attack: AttackComponent


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_attack = AttackComponent.new()
	_attack.data = load("res://resources/attacks/basic_attack.tres") as AttackData
	_attack.projectile_root = _root
	add_child_autofree(_attack)


func test_fire_spawns_projectile_with_direction() -> void:
	var projectile := _attack.try_fire(Vector2(5, 5), Vector2.RIGHT) as Projectile
	assert_not_null(projectile)
	assert_eq(projectile.global_position, Vector2(5, 5))
	assert_eq(projectile.direction, Vector2.RIGHT)
	assert_eq(projectile.get_parent(), _root)


func test_cooldown_blocks_second_shot_then_allows() -> void:
	assert_not_null(_attack.try_fire(Vector2.ZERO, Vector2.RIGHT))
	assert_null(_attack.try_fire(Vector2.ZERO, Vector2.RIGHT))
	_attack._process(_attack.data.cooldown + 0.05)
	assert_not_null(_attack.try_fire(Vector2.ZERO, Vector2.RIGHT))


func test_zero_direction_does_not_fire() -> void:
	assert_null(_attack.try_fire(Vector2.ZERO, Vector2.ZERO))


func test_missing_data_does_not_fire() -> void:
	_attack.data = null
	assert_null(_attack.try_fire(Vector2.ZERO, Vector2.RIGHT))
