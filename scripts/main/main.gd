class_name Main
extends Node2D
## Wires the main scene together: health bar to the player, death screen to player death.

@onready var _player: Player = $Player
@onready var _death_screen: DeathScreen = $DeathScreen
@onready var _health_bar: HealthBar = $Hud/HealthBar


func _ready() -> void:
	_health_bar.bind(_player.health)
	_player.died.connect(_death_screen.show_death)
