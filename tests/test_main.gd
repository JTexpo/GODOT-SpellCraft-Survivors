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


func _main() -> Main:
	var main := load("res://scenes/main/main.tscn").instantiate() as Main
	add_child_autofree(main)
	return main


func _action(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_collecting_a_scroll_shows_the_toast_and_updates_the_button() -> void:
	var main := _main()
	var player := main.get_node("Player") as Player
	var pickup := (load("res://scenes/scrolls/scroll_pickup.tscn") as PackedScene).instantiate() as ScrollPickup
	main.add_child(pickup)
	pickup.setup(load("res://resources/scrolls/base/fire.tres") as ScrollData)
	pickup.global_position = player.global_position
	await wait_physics_frames(4)
	assert_true((main.get_node("Hud/ScrollToast") as ScrollToast).is_showing())
	assert_eq((main.get_node("Hud/ScrollToast") as ScrollToast).text, "+ Fire Scroll")
	assert_eq((main.get_node("Hud/InventoryButton") as InventoryButton).total, 1)


func test_toggle_action_opens_the_panel_and_a_dead_player_cannot() -> void:
	var main := _main()
	var panel := main.get_node("Hud/InventoryPanel") as InventoryPanel
	main._unhandled_input(_action(&"toggle_inventory"))
	assert_true(panel.is_open())
	main._unhandled_input(_action(&"toggle_inventory"))
	assert_false(panel.is_open())
	(main.get_node("Player/HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	main._unhandled_input(_action(&"toggle_inventory"))
	assert_false(panel.is_open())


func test_the_button_toggles_the_panel() -> void:
	var main := _main()
	var panel := main.get_node("Hud/InventoryPanel") as InventoryPanel
	(main.get_node("Hud/InventoryButton") as InventoryButton).pressed.emit()
	assert_true(panel.is_open())


func test_debug_key_gives_three_of_every_scroll() -> void:
	var main := _main()
	var player := main.get_node("Player") as Player
	main._unhandled_input(_action(&"debug_give_scrolls"))
	assert_eq(main.debug_scrolls.size(), 15)
	assert_eq(player.inventory.total_count(), 45)
	for scroll in main.debug_scrolls:
		assert_eq(player.inventory.count(scroll), 3)


func test_player_death_closes_the_panel() -> void:
	var main := _main()
	var panel := main.get_node("Hud/InventoryPanel") as InventoryPanel
	panel.set_open(true)
	(main.get_node("Player/HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_false(panel.is_open())


func test_player_death_hides_the_inventory_button_so_restart_taps_get_through() -> void:
	var main := _main()
	var button := main.get_node("Hud/InventoryButton") as InventoryButton
	assert_true(button.visible)
	(main.get_node("Player/HurtboxComponent") as HurtboxComponent).receive_hit(1000.0, Vector2.ZERO)
	assert_false(button.visible)
	watch_signals(button)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(button.global_position + button.size / 2.0)
	button._input(touch)
	assert_signal_not_emitted(button, "pressed")
