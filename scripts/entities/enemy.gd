class_name Enemy
extends CharacterBody2D

@export var speed_scale: float = 0.33

@onready var _move: MoveComponent = $MoveComponent


func _physics_process(_delta: float) -> void:
	_move.apply(self, direction_to_target() * speed_scale)


func direction_to_target() -> Vector2:
	var target := get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return Vector2.ZERO
	return global_position.direction_to(target.global_position)
