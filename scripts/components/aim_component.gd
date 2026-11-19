class_name AimComponent
extends Node
## Turns mouse, right stick and the touch aim stick into one aim direction, an aim point and a
## "firing" flag. A held stick wins. The mouse takes over again once it moves.

enum Source { MOUSE, STICK }

const STICK_THRESHOLD := 0.2
## How far out the aim point is when a stick aims. Ground-targeted spells clamp it to their range.
const FAR_DISTANCE := 10000.0

var aim_direction: Vector2 = Vector2.RIGHT
## Where the player points: the cursor for the mouse, a far point along the direction for a stick.
var aim_point: Vector2 = Vector2.ZERO
var is_firing: bool = false
var source: Source = Source.MOUSE

var _last_mouse_screen: Vector2 = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return
	var mouse_screen := get_viewport().get_mouse_position()
	var mouse_moved := mouse_screen != _last_mouse_screen
	_last_mouse_screen = mouse_screen
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	update_aim(
		owner_node.global_position,
		owner_node.get_global_mouse_position(),
		stick,
		Input.is_action_pressed(&"cast"),
		mouse_moved,
	)


func update_aim(origin: Vector2, mouse_position: Vector2, stick: Vector2, firing: bool, mouse_moved: bool) -> void:
	is_firing = firing
	if stick.length() > STICK_THRESHOLD:
		aim_direction = stick.normalized()
		source = Source.STICK
	else:
		if mouse_moved:
			source = Source.MOUSE
		if source == Source.MOUSE:
			var to_mouse := mouse_position - origin
			if to_mouse.length() > 0.001:
				aim_direction = to_mouse.normalized()
	aim_point = mouse_position if source == Source.MOUSE else origin + aim_direction * FAR_DISTANCE
