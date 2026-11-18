class_name Player
extends CharacterBody2D

@onready var _move: MoveComponent = $MoveComponent


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_move.apply(self, direction)
