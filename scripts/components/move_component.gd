class_name MoveComponent
extends Node

@export var speed: float = 90.0


func apply(body: CharacterBody2D, direction: Vector2, extra_velocity: Vector2 = Vector2.ZERO) -> void:
	body.velocity = direction.limit_length(1.0) * speed + extra_velocity
	body.move_and_slide()
