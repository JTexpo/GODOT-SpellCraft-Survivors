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


func test_spell_bar_is_bound_and_slot_presses_select() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var player := main.get_node("Player") as Player
	var bar := main.get_node("Hud/SpellBar") as SpellBar
	assert_eq(bar.widgets.size(), 5)
	bar.slot_pressed.emit(1)
	assert_eq(player.loadout.selected_index, 1)


func test_debug_key_refills_drained_mana() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var player := main.get_node("Player") as Player
	player.loadout.selected().current_mana = 0.0
	var event := InputEventAction.new()
	event.action = &"debug_restore_mana"
	event.pressed = true
	main._unhandled_input(event)
	assert_eq(player.loadout.selected().current_mana, player.loadout.selected().data.max_mana)


func test_dead_player_cannot_change_spell_by_tapping_the_bar() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var player := main.get_node("Player") as Player
	var bar := main.get_node("Hud/SpellBar") as SpellBar
	(player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = bar.widgets[1].get_global_rect().get_center()
	bar.widgets[1]._input(touch)
	assert_eq(player.loadout.selected_index, 0)
	assert_false(bar.visible)


func test_main_has_a_bound_target_reticle() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var reticle := main.get_node("TargetReticle") as TargetReticle
	assert_not_null(reticle)
	reticle._process(0.0)
	assert_false(reticle.visible)


func test_enemy_hits_show_damage_numbers_but_player_hits_do_not() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var numbers := main.get_node("DamageNumbers") as DamageNumbers
	var spawner := main.get_node("EnemySpawner") as EnemySpawner
	var enemy := spawner.spawn_at(Vector2(100, 100))
	(enemy.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(10.0, Vector2.ZERO, 0.0, SpellData.Element.FIRE)
	assert_eq(numbers.active_count(), 1)
	var player := main.get_node("Player") as Player
	(player.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(10.0, Vector2.ZERO)
	assert_eq(numbers.active_count(), 1)


func test_killing_an_enemy_can_drop_a_scroll() -> void:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	var spawner := main.get_node("EnemySpawner") as EnemySpawner
	var enemy := spawner.spawn_at(Vector2(100, 100))
	enemy.data = enemy.data.duplicate() as EnemyData
	enemy.data.drop_table = enemy.data.drop_table.duplicate() as DropTable
	enemy.data.drop_table.drop_chance = 1.0
	(enemy.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	var found := 0
	for pickup in get_tree().get_nodes_in_group(&"scroll_pickups"):
		if main.is_ancestor_of(pickup):
			found += 1
	assert_eq(found, 1)
