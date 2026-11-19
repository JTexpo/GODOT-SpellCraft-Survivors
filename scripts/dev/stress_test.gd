class_name StressTest
extends Node2D
## Development tool: keeps `enemy_count` full enemies alive around the player while a rotating
## attacker fires, and reports frame time. Not part of the player-facing game.
##
## Run: godot --path . res://scenes/world/stress_test.tscn -- --enemies=300 --seconds=10

const WARMUP_FRAMES := 30
const SPAWN_RADIUS_MIN := 40.0
const SPAWN_RADIUS_MAX := 200.0
const SPIN_SPEED := 7.0
const STRESS_SPELL := preload("res://resources/spells/stress_spell.tres")
## --area=<name> stresses that Area's starting spell instead of the default Missile.
const AREA_SPELLS := {
	"missile": "res://resources/spells/fire_missile.tres",
	"cone": "res://resources/spells/thunder_cone.tres",
	"zone": "res://resources/spells/land_area.tres",
	"line": "res://resources/spells/sea_line.tres",
	"wave": "res://resources/spells/sea_wave.tres",
}

@export var enemy_count: int = 300
## 0 means run until closed. Above 0 it prints one STRESS line and quits.
@export var run_seconds: float = 0.0
## Empty means the default stress spell. Otherwise a key of AREA_SPELLS.
@export var area_name: String = ""

var _frame_ms: Array[float] = []
var _physics_ms_total: float = 0.0
var _process_ms_total: float = 0.0
var _samples: int = 0
var _elapsed: float = 0.0
var _frames: int = 0
var _angle: float = 0.0
var _label_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

@onready var _spawner: EnemySpawner = $EnemySpawner
@onready var _player: Player = $Player
@onready var _loadout: SpellLoadout = $Player/SpellLoadout
@onready var _label: Label = $Hud/Label
@onready var _damage_numbers: DamageNumbers = $DamageNumbers


func _ready() -> void:
	_read_command_line()
	_rng.randomize()
	_spawner.set_process(false)
	_spawner.enemy_damaged.connect(_damage_numbers.show_number)
	_player.health.set_max_health(1.0e9)
	_loadout.slots[0] = SpellInstance.new(_stress_spell())
	_loadout.select(0)
	if run_seconds > 0.0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	for i in enemy_count:
		_spawn_one()


func _physics_process(delta: float) -> void:
	_angle += SPIN_SPEED * delta
	_loadout.try_cast(_player.global_position, Vector2.from_angle(_angle))


func _process(delta: float) -> void:
	_frames += 1
	_label_timer += delta
	if _label_timer >= 0.25:
		_label_timer = 0.0
		_label.text = "enemies %d  fps %d  frame %.1f ms" % [enemy_count, Engine.get_frames_per_second(), delta * 1000.0]
	if run_seconds <= 0.0 or _frames <= WARMUP_FRAMES:
		return
	_elapsed += delta
	_frame_ms.append(delta * 1000.0)
	_physics_ms_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_process_ms_total += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_samples += 1
	if _elapsed >= run_seconds:
		_report_and_quit()


## The named Area's spell with a bottomless pool and a fast interval, so it never runs dry.
func _stress_spell() -> SpellData:
	if not AREA_SPELLS.has(area_name):
		if area_name != "":
			push_error("Unknown --area=%s (use %s)" % [area_name, ", ".join(AREA_SPELLS.keys())])
		return STRESS_SPELL
	var spell := (load(AREA_SPELLS[area_name]) as SpellData).duplicate() as SpellData
	spell.max_mana = STRESS_SPELL.max_mana
	spell.cast_interval = STRESS_SPELL.cast_interval
	return spell


func _spawn_one() -> void:
	var offset := Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	var enemy := _spawner.spawn_at(_player.global_position + offset)
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Enemy) -> void:
	_spawn_one.call_deferred()


func _read_command_line() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--enemies="):
			enemy_count = int(argument.get_slice("=", 1))
		elif argument.begins_with("--seconds="):
			run_seconds = float(argument.get_slice("=", 1))
		elif argument.begins_with("--area="):
			area_name = argument.get_slice("=", 1)


func _report_and_quit() -> void:
	var report := StressReport.summarize(_frame_ms)
	print("STRESS enemies=%d avg_fps=%.1f avg_frame_ms=%.2f p99_frame_ms=%.2f avg_physics_ms=%.2f avg_process_ms=%.2f" % [
		enemy_count,
		report["avg_fps"],
		report["avg_ms"],
		report["p99_ms"],
		_physics_ms_total / maxf(_samples, 1),
		_process_ms_total / maxf(_samples, 1),
	])
	get_tree().quit()
