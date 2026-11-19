class_name Player
extends CharacterBody2D

signal died

@onready var health: HealthComponent = $HealthComponent
@onready var _move: MoveComponent = $MoveComponent
@onready var _hurtbox: HurtboxComponent = $HurtboxComponent
@onready var _knockback: KnockbackComponent = $KnockbackComponent
@onready var _flash: HitFlashComponent = $HitFlashComponent


func _ready() -> void:
	_hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_move.apply(self, direction, _knockback.update(delta))


func _on_hit_received(_damage: float, source_position: Vector2, knockback: float) -> void:
	_knockback.apply_impulse(global_position - source_position, knockback)
	_flash.flash()


func _on_died() -> void:
	remove_from_group(&"player")
	died.emit()
