class_name InteractionComponent
extends Area2D
## The player's way to use things in the world (Lecterns). It watches the interactable layer, keeps
## track of the nearest one in range, shows its prompt, and interacts with it on request. A dead
## owner has no target and cannot interact.

signal target_changed(target: Node)
signal interacted(target: Node)

@export var health: HealthComponent

var _target: Node


func _physics_process(_delta: float) -> void:
	var nearest: Node = null
	if health == null or not health.is_dead():
		nearest = _find_nearest()
	if nearest == _target:
		return
	_set_prompt(_target, false)
	_target = nearest
	_set_prompt(_target, true)
	target_changed.emit(_target)


func target() -> Node:
	return _target if is_instance_valid(_target) else null


func try_interact(actor: Node) -> bool:
	var current := target()
	if current == null or (health != null and health.is_dead()):
		return false
	current.interact(actor)
	interacted.emit(current)
	return true


func _find_nearest() -> Node:
	var best: Node = null
	var best_distance := INF
	for area in get_overlapping_areas():
		if not area.has_method(&"interact"):
			continue
		var distance := global_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best


func _set_prompt(node: Node, value: bool) -> void:
	if is_instance_valid(node) and node.has_method(&"set_prompt_visible"):
		node.set_prompt_visible(value)
