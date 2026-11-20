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
@onready var _xp_dropper: XpDropper = $XpDropper
@onready var _saver: ProfileSaver = $ProfileSaver
@onready var _pick_screen: BuffPickScreen = $BuffPickScreen
@onready var _xp_bar: XpBar = $Hud/XpBar
@onready var _level_toast: LevelToast = $Hud/LevelToast

## Where the profile is saved. Empty means "do not load or save": tests set it before adding Main to
## the tree so they never touch the player's real save.
@export var save_path: String = SaveGame.DEFAULT_PATH

var profile: PlayerProfile
var track: LevelTrack

var _rng := RandomNumberGenerator.new()


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
	_begin_progression()


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
	# DEBUG: 100 XP, to try levels without grinding. It is saved like real XP. Delete later.
	elif event.is_action_pressed(&"debug_give_xp"):
		_player.progress.add_xp(100)


## Loads the profile, wires XP and saving, asks for any owed buff pick, then sets the run up. With
## nothing to ask it finishes straight away. With a pick owed it waits on the pick screen (the world
## is paused meanwhile), so the run starts with the choice already applied.
func _begin_progression() -> void:
	_rng.randomize()
	track = LevelTrack.default_track()
	profile = SaveGame.load_profile(save_path) if not save_path.is_empty() else PlayerProfile.new()
	var progress := _player.progress
	progress.bind(_player, profile, track)
	progress.starting_buffs_hook = _on_random_buff_reached
	_saver.bind(profile, save_path)
	_xp_bar.bind(progress)
	_player.collector.xp_collected.connect(progress.add_xp)
	_spawner.enemy_died.connect(_xp_dropper.on_enemy_died)
	progress.xp_changed.connect(_on_xp_changed)
	progress.leveled_up.connect(_on_leveled_up)
	_player.died.connect(_on_player_died)
	var level := profile.level(track)
	if not StartingBuffs.settle_random(profile, track, level, _rng).is_empty():
		_saver.mark_dirty()
	for reward_level in StartingBuffs.unresolved_levels(profile, track, level, LevelReward.Kind.CHOSEN_BUFF):
		var options := StartingBuffs.options_for(profile, track, reward_level)
		if options.is_empty():
			continue
		_pick_screen.open(options, "Level %d: choose a buff for your starting spell" % reward_level)
		var picked: ScrollData = await _pick_screen.chosen
		profile.set_pick(reward_level, picked.id)
		_saver.save_now()
	RunStart.prepare(_player, profile, track)


func _on_random_buff_reached(_reward_level: int) -> void:
	StartingBuffs.settle_random(profile, track, _player.progress.level(), _rng)
	_saver.mark_dirty()


func _on_xp_changed(_total_xp: int, _level: int) -> void:
	_saver.mark_dirty()


func _on_leveled_up(level: int, reward: LevelReward) -> void:
	_level_toast.show_level_up(level, reward, _buff_notice(level, reward))
	_saver.save_now()


## For a random buff: what the starting spell will gain next run. Empty for any other reward.
func _buff_notice(level: int, reward: LevelReward) -> String:
	if reward.kind != LevelReward.Kind.RANDOM_BUFF:
		return ""
	var scroll := StartingBuffs.find_scroll(track, profile.pick(level))
	if scroll == null:
		return ""
	var spell_name := "Starting spell" if reward.spell_index == 0 else "Second spell"
	return "%s gains %s next run" % [spell_name, scroll.display_name]


func _on_player_died() -> void:
	_death_screen.set_run_summary(_player.progress.run_xp, _player.progress.level())
	_saver.save_now()


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
