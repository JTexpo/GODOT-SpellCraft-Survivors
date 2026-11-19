extends GutTest

var _root: Node2D
var _inventory: ScrollInventory
var _loadout: SpellLoadout
var _screen: CraftingScreen
var _fire: ScrollData
var _thunder: ScrollData
var _missile: ScrollData
var _wave: ScrollData


func _scroll(path: String) -> ScrollData:
	return load("res://resources/scrolls/%s.tres" % path) as ScrollData


func before_each() -> void:
	_root = Node2D.new()
	add_child_autofree(_root)
	_inventory = ScrollInventory.new()
	add_child_autofree(_inventory)
	var spells: Array[SpellData] = [load("res://resources/spells/fire_missile.tres") as SpellData]
	_loadout = SpellLoadout.new()
	_loadout.starting_spells = spells
	_loadout.unlocked_slots = 1
	_loadout.projectile_root = _root
	add_child_autofree(_loadout)
	_screen = load("res://scenes/ui/crafting_screen.tscn").instantiate() as CraftingScreen
	_screen.pause_tree = false
	add_child_autofree(_screen)
	_fire = _scroll("base/fire")
	_thunder = _scroll("base/thunder")
	_missile = _scroll("area/missile")
	_wave = _scroll("area/wave")


func after_each() -> void:
	get_tree().paused = false
	GameTime.reset()


func _action(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_starts_closed_and_hidden() -> void:
	assert_false(_screen.is_open())
	assert_false(_screen.visible)


func test_open_shows_it_and_close_hides_it_and_emits_closed_once() -> void:
	watch_signals(_screen)
	_screen.open(_inventory, _loadout)
	assert_true(_screen.is_open())
	assert_true(_screen.visible)
	_screen.close()
	_screen.close()
	assert_false(_screen.is_open())
	assert_false(_screen.visible)
	assert_signal_emit_count(_screen, "closed", 1)


func test_open_pauses_and_close_unpauses_when_enabled() -> void:
	_screen.pause_tree = true
	_screen.open(_inventory, _loadout)
	var paused_while_open := get_tree().paused
	var clock_frozen := GameTime.is_frozen()
	_screen.close()
	assert_true(paused_while_open)
	assert_true(clock_frozen)
	assert_false(get_tree().paused)
	assert_false(GameTime.is_frozen())


func test_empty_inventory_opens_with_confirm_disabled_and_a_reason() -> void:
	_screen.open(_inventory, _loadout)
	assert_false(_screen.confirm_enabled())
	assert_false(_screen.message_text().is_empty())


func test_preview_matches_the_builder() -> void:
	_inventory.add(_thunder)
	_inventory.add(_wave)
	_screen.open(_inventory, _loadout)
	assert_true(_screen.choose_base(_thunder))
	assert_true(_screen.choose_area(_wave))
	assert_true(_screen.choose_range(2))
	var built := SpellBuilder.build(_thunder, _wave, CraftingRules.default_rules().option(2))
	var text := _screen.preview_text()
	assert_true(text.contains("Thunder Wave (Long)"), text)
	assert_true(text.contains("%.1f" % built.mana_cost), text)
	assert_true(text.contains("%d" % roundi(built.max_mana)), text)
	assert_true(_screen.confirm_enabled())


func test_current_spell_is_shown_beside_the_preview() -> void:
	_screen.open(_inventory, _loadout)
	assert_true(_screen.preview_text().contains("Fire Missile"))
	assert_true(_screen.preview_text().contains("Replaces Fire Missile"))


func test_confirm_crafts_consumes_and_closes() -> void:
	_inventory.add(_thunder)
	_inventory.add(_missile)
	_screen.open(_inventory, _loadout)
	watch_signals(_screen)
	_screen.choose_base(_thunder)
	_screen.choose_area(_missile)
	_screen.confirm()
	assert_eq(_loadout.slots[0].data.id, &"thunder_missile_normal")
	assert_eq(_inventory.count(_thunder), 0)
	assert_eq(_inventory.count(_missile), 0)
	assert_false(_screen.is_open())
	assert_signal_emit_count(_screen, "closed", 1)


func test_confirm_when_invalid_shows_the_reason_and_changes_nothing() -> void:
	_inventory.add(_thunder)
	_screen.open(_inventory, _loadout)
	var before := _loadout.slots[0]
	_screen.choose_base(_thunder)
	_screen.confirm()
	assert_true(_screen.is_open())
	assert_eq(_screen.message_text(), CraftingSystem.REASON_NO_AREA)
	assert_eq(_inventory.count(_thunder), 1)
	assert_eq(_loadout.slots[0], before)


func test_cancel_changes_nothing_and_closes() -> void:
	_inventory.add(_thunder)
	_inventory.add(_missile)
	_screen.open(_inventory, _loadout)
	_screen.choose_base(_thunder)
	_screen.choose_area(_missile)
	var before := _loadout.slots[0]
	_screen.cancel()
	assert_false(_screen.is_open())
	assert_eq(_loadout.slots[0], before)
	assert_eq(_inventory.total_count(), 2)


func test_locked_slot_cannot_be_chosen() -> void:
	_screen.open(_inventory, _loadout)
	assert_false(_screen.choose_slot(1))
	assert_eq(_screen.session.slot_index, 0)


func test_buffs_are_shown_locked() -> void:
	var buff := _scroll("buff/damage")
	_inventory.add(buff)
	_screen.open(_inventory, _loadout)
	var text := _screen.buffs_text()
	assert_true(text.contains("Increased Damage"), text)
	assert_true(text.to_lower().contains("locked"), text)
	assert_false(_screen.choose_base(buff))
	assert_false(_screen.choose_area(buff))


func test_ui_cancel_and_pause_actions_close_it() -> void:
	_screen.open(_inventory, _loadout)
	_screen._unhandled_input(_action(&"ui_cancel"))
	assert_false(_screen.is_open())
	_screen.open(_inventory, _loadout)
	_screen._unhandled_input(_action(&"pause"))
	assert_false(_screen.is_open())


func test_actions_are_ignored_while_closed() -> void:
	_screen._unhandled_input(_action(&"ui_cancel"))
	assert_false(_screen.is_open())


func test_touch_is_bridged_while_open_and_ignored_while_closed() -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(40, 40)
	assert_false(_screen.handle_input(touch), "closed")
	_screen.open(_inventory, _loadout)
	assert_true(_screen.handle_input(touch), "open")
	var drag := InputEventScreenDrag.new()
	assert_false(_screen.handle_input(drag), "only touches are bridged")


func test_choices_survive_a_rebuild_and_buttons_exist() -> void:
	_inventory.add(_fire, 2)
	_inventory.add(_missile)
	_screen.open(_inventory, _loadout)
	assert_eq(_screen.base_button_count(), 1)
	assert_eq(_screen.area_button_count(), 1)
	assert_eq(_screen.range_button_count(), 4)
	_screen.choose_base(_fire)
	assert_eq(_screen.session.base, _fire)
	assert_eq(_screen.base_button_count(), 1)


func _touch(pressed: bool, at: Vector2) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.pressed = pressed
	touch.position = at
	return touch


func test_a_bridged_touch_does_not_press_the_global_cast_action() -> void:
	# The synthetic left click would otherwise also press `cast` (bound to the left mouse button),
	# and a finger held down when the screen closes could keep it pressed.
	_screen.open(_inventory, _loadout)
	_screen.handle_input(_touch(true, Vector2(40, 40)))
	await wait_process_frames(2)
	var pressed_cast := Input.is_action_pressed(&"cast")
	_screen.handle_input(_touch(false, Vector2(40, 40)))
	await wait_process_frames(2)
	Input.action_release(&"cast")
	assert_false(pressed_cast, "a bridged touch must not press the cast action")

