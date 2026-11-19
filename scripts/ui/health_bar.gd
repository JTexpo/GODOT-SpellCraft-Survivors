class_name HealthBar
extends Control
## TEMPORARY (Sprint 1): placeholder player health bar. The real HUD gets its own sprint.

var ratio: float = 1.0

@onready var _background: ColorRect = $Background
@onready var _fill: ColorRect = $Background/Fill


func bind(health: HealthComponent) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	ratio = current / maximum if maximum > 0.0 else 0.0
	_fill.size.x = _background.size.x * ratio
