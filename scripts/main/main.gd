class_name Main
extends Node2D
## Wires the main scene together: health and spell bars to the player, death screen to player death.

@onready var _player: Player = $Player
@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _health_bar: HealthBar = $Hud/HealthBar
@onready var _spell_bar: SpellBar = $Hud/SpellBar
@onready var _reticle: TargetReticle = $TargetReticle
@onready var _spawner: EnemySpawner = $EnemySpawner
@onready var _damage_numbers: DamageNumbers = $DamageNumbers
@onready var _dropper: ScrollDropper = $ScrollDropper


func _ready() -> void:
	_health_bar.bind(_player.health)
	_player.died.connect(_death_screen.show_death)
	# A hidden bar ignores touches, so a dead player can't change spell and the restart tap gets through.
	_player.died.connect(_spell_bar.hide)
	_spell_bar.bind(_player.loadout)
	_reticle.bind(_player)
	_spawner.enemy_damaged.connect(_damage_numbers.show_number)
	_spawner.enemy_died.connect(_dropper.on_enemy_died)
	_spell_bar.slot_pressed.connect(_player.loadout.select)


# DEBUG: refills every spell's mana. Delete once potions and drops exist.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_restore_mana"):
		_player.loadout.restore_all_mana()
