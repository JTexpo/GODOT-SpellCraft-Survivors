class_name Main
extends Node2D
## Wires the main scene together: health and spell bars to the player, death screen to player death.

## DEBUG: the scrolls F10 hands out (3 of each). Delete with the debug key.
@export var debug_scrolls: Array[ScrollData] = []

@onready var _player: Player = $Player
@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _health_bar: HealthBar = $Hud/HealthBar
@onready var _spell_bar: SpellBar = $Hud/SpellBar
@onready var _reticle: TargetReticle = $TargetReticle
@onready var _spawner: EnemySpawner = $EnemySpawner
@onready var _damage_numbers: DamageNumbers = $DamageNumbers
@onready var _dropper: ScrollDropper = $ScrollDropper
@onready var _toast: ScrollToast = $Hud/ScrollToast
@onready var _inventory_panel: InventoryPanel = $Hud/InventoryPanel
@onready var _inventory_button: InventoryButton = $Hud/InventoryButton
@onready var _interact_button: InteractButton = $Hud/InteractButton
@onready var _crafting_screen: CraftingScreen = $CraftingScreen


func _ready() -> void:
	GameTime.reset()
	_health_bar.bind(_player.health)
	_player.died.connect(_death_screen.show_death)
	# A hidden bar ignores touches, so a dead player can't change spell and the restart tap gets through.
	_player.died.connect(_spell_bar.hide)
	_spell_bar.bind(_player.loadout)
	_reticle.bind(_player)
	_spawner.enemy_damaged.connect(_damage_numbers.show_number)
	_spawner.enemy_died.connect(_dropper.on_enemy_died)
	_inventory_panel.bind(_player.inventory)
	_player.collector.collected.connect(_toast.show_scroll)
	_player.inventory.changed.connect(_on_inventory_changed)
	_inventory_button.set_total(_player.inventory.total_count())
	_inventory_button.pressed.connect(_toggle_inventory)
	_player.died.connect(_inventory_panel.set_open.bind(false))
	# A hidden button ignores touches, so the restart tap gets through after death.
	_player.died.connect(_inventory_button.hide)
	_spell_bar.slot_pressed.connect(_player.loadout.select)
	_player.interaction.target_changed.connect(_on_interaction_target_changed)
	_interact_button.pressed.connect(_player.interaction.try_interact.bind(_player))
	_player.died.connect(_interact_button.hide)
	for lectern in get_tree().get_nodes_in_group(&"lecterns"):
		if is_ancestor_of(lectern):
			lectern.interacted.connect(_open_crafting)
	# The click that confirmed a craft is probably still held when the world resumes.
	_crafting_screen.closed.connect(_player.require_cast_release)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		_toggle_inventory()
	# DEBUG: refills every spell's mana. Delete once potions exist.
	elif event.is_action_pressed(&"debug_restore_mana"):
		_player.loadout.restore_all_mana()
	# DEBUG: 3 of every scroll, to try the panel and crafting without grinding. Delete later.
	elif event.is_action_pressed(&"debug_give_scrolls"):
		for scroll in debug_scrolls:
			_player.inventory.add(scroll, 3)
	# DEBUG: unlocks the next spell slot, until levels do it (Sprint 8). Delete then.
	elif event.is_action_pressed(&"debug_unlock_slot"):
		_player.loadout.unlock_next()


func _toggle_inventory() -> void:
	if _player.health.is_dead():
		return
	_inventory_panel.toggle()


func _open_crafting(_actor: Node) -> void:
	if _player.health.is_dead() or _crafting_screen.is_open():
		return
	_crafting_screen.open(_player.inventory, _player.loadout)


func _on_interaction_target_changed(target: Node) -> void:
	_interact_button.set_available(target != null)


func _on_inventory_changed(_scroll: ScrollData) -> void:
	_inventory_button.set_total(_player.inventory.total_count())
