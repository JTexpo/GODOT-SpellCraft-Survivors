extends GutTest

const LECTERN := "res://scenes/interactables/lectern.tscn"

var _root: Node2D
var _player: Player


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = load("res://scenes/player/player.tscn").instantiate() as Player
	_root.add_child(_player)
	_player.global_position = Vector2(300, 300)


func _lectern(offset: Vector2) -> Lectern:
	var lectern := (load(LECTERN) as PackedScene).instantiate() as Lectern
	_root.add_child(lectern)
	lectern.global_position = _player.global_position + offset
	return lectern


func _prompt_visible(lectern: Lectern) -> bool:
	return (lectern.get_node("Prompt") as Label).visible


func test_nearest_lectern_becomes_the_target_and_shows_its_prompt() -> void:
	var far := _lectern(Vector2(30, 0))
	var near := _lectern(Vector2(10, 0))
	await wait_physics_frames(4)
	assert_eq(_player.interaction.target(), near)
	assert_true(_prompt_visible(near))
	assert_false(_prompt_visible(far))


func test_out_of_range_is_no_target() -> void:
	var lectern := _lectern(Vector2(200, 0))
	await wait_physics_frames(4)
	assert_null(_player.interaction.target())
	assert_false(_player.interaction.try_interact(_player))
	assert_false(_prompt_visible(lectern))


func test_walking_away_clears_the_target_and_hides_the_prompt() -> void:
	var lectern := _lectern(Vector2(10, 0))
	await wait_physics_frames(4)
	assert_eq(_player.interaction.target(), lectern)
	lectern.global_position += Vector2(400, 0)
	await wait_physics_frames(4)
	assert_null(_player.interaction.target())
	assert_false(_prompt_visible(lectern))


func test_interact_calls_the_target_and_emits() -> void:
	var lectern := _lectern(Vector2(10, 0))
	await wait_physics_frames(4)
	watch_signals(lectern)
	watch_signals(_player.interaction)
	assert_true(_player.interaction.try_interact(_player))
	assert_signal_emitted_with_parameters(lectern, "interacted", [_player])
	assert_signal_emitted_with_parameters(_player.interaction, "interacted", [lectern])


func test_dead_player_cannot_interact() -> void:
	var lectern := _lectern(Vector2(10, 0))
	(_player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	await wait_physics_frames(4)
	watch_signals(lectern)
	assert_null(_player.interaction.target())
	assert_false(_player.interaction.try_interact(_player))
	assert_signal_not_emitted(lectern, "interacted")
	assert_false(_prompt_visible(lectern))


func test_target_changed_emits_only_on_change() -> void:
	watch_signals(_player.interaction)
	var lectern := _lectern(Vector2(10, 0))
	await wait_physics_frames(8)
	assert_signal_emit_count(_player.interaction, "target_changed", 1)
	assert_signal_emitted_with_parameters(_player.interaction, "target_changed", [lectern])
