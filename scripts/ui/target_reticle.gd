class_name TargetReticle
extends Node2D
## TEMPORARY (Sprint 3): a small ring showing where a ground-targeted spell will land. Visible
## only while such a spell is selected and the player is alive. Reads the player, changes nothing.

const RADIUS := 5.0

var _player: Player


func _ready() -> void:
	visible = false


func bind(player: Player) -> void:
	_player = player


func _process(_delta: float) -> void:
	var spell := _player.loadout.selected() if _player != null else null
	var shown := (
		spell != null
		and spell.data.area_data != null
		and spell.data.area_data.needs_ground_target
		and not _player.health.is_dead()
	)
	visible = shown
	if shown:
		global_position = spell.data.clamp_target(_player.global_position, _player.aim.aim_point)


func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, Color.WHITE, 1.0)
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
