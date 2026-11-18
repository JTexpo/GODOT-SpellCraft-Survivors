extends GutTest


func _make_enemy() -> Enemy:
	var enemy := load("res://scenes/enemies/base_enemy.tscn").instantiate() as Enemy
	add_child_autofree(enemy)
	enemy.global_position = Vector2.ZERO
	return enemy


func test_direction_points_at_player() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.add_to_group(&"player")
	player.global_position = Vector2(100, 0)
	var enemy := _make_enemy()
	assert_eq(enemy.direction_to_target(), Vector2.RIGHT)


func test_no_player_returns_zero() -> void:
	var enemy := _make_enemy()
	assert_eq(enemy.direction_to_target(), Vector2.ZERO)
