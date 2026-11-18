extends GutTest


func _make_body() -> CharacterBody2D:
	var body := CharacterBody2D.new()
	add_child_autofree(body)
	return body


func test_diagonal_not_faster() -> void:
	var move := MoveComponent.new()
	add_child_autofree(move)
	var body := _make_body()
	move.apply(body, Vector2(1, 1))
	assert_almost_eq(body.velocity.length(), move.speed, 0.01)


func test_zero_direction_stops() -> void:
	var move := MoveComponent.new()
	add_child_autofree(move)
	var body := _make_body()
	body.velocity = Vector2(50, 50)
	move.apply(body, Vector2.ZERO)
	assert_eq(body.velocity, Vector2.ZERO)
