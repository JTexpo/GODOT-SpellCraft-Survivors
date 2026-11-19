class_name Player
extends CharacterBody2D

signal died

const SLOT_ACTIONS: Array[StringName] = [
	&"spell_slot_1", &"spell_slot_2", &"spell_slot_3", &"spell_slot_4", &"spell_slot_5",
]

@onready var health: HealthComponent = $HealthComponent
@onready var _move: MoveComponent = $MoveComponent
@onready var _hurtbox: HurtboxComponent = $HurtboxComponent
@onready var _knockback: KnockbackComponent = $KnockbackComponent
@onready var _flash: HitFlashComponent = $HitFlashComponent
@onready var aim: AimComponent = $AimComponent
@onready var loadout: SpellLoadout = $SpellLoadout
@onready var inventory: ScrollInventory = $ScrollInventory


func _ready() -> void:
	_hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_move.apply(self, direction, _knockback.update(delta))
	if aim.is_firing:
		loadout.try_cast(global_position, aim.aim_direction, aim.aim_point)
	else:
		loadout.end_cast()


func _unhandled_input(event: InputEvent) -> void:
	if health.is_dead():
		return
	for index in SLOT_ACTIONS.size():
		if event.is_action_pressed(SLOT_ACTIONS[index]):
			loadout.select(index)
			return
	if event.is_action_pressed(&"spell_prev"):
		loadout.cycle(-1)
	elif event.is_action_pressed(&"spell_next"):
		loadout.cycle(1)


func _on_hit_received(_damage: float, source_position: Vector2, knockback: float, _effect: int) -> void:
	_knockback.apply_impulse(global_position - source_position, knockback)
	_flash.flash()


func _on_died() -> void:
	remove_from_group(&"player")
	died.emit()
