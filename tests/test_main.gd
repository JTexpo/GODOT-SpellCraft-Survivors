extends GutTest


func test_player_death_shows_death_screen_and_bar_tracks_health() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var player := main.get_node("Player") as Player
	var death_screen := main.get_node("DeathScreen") as DeathScreen
	var bar := main.get_node("Hud/HealthBar") as HealthBar
	assert_false(death_screen.visible)
	assert_eq(bar.ratio, 1.0)
	(player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(30.0, Vector2.ZERO)
	assert_eq(bar.ratio, 0.7)
	await wait_seconds(0.6)
	(player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_true(death_screen.visible)
