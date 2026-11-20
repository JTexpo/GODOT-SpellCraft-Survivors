class_name XpDropper
extends Node
## Turns an enemy's death into an XP gem on the ground. Keeps at most `max_gems` out: at the cap a
## new drop's value is added to the oldest gem instead of being dropped, so no XP is ever lost.

@export var gem_scene: PackedScene
@export var max_gems: int = 150

## Where gems are added. Defaults to this node's parent.
var drop_root: Node

## Oldest first.
var _gems: Array[XpGem] = []


## The gem that received the XP, or null if the enemy gives none.
func on_enemy_died(enemy: Enemy) -> XpGem:
	if enemy == null or enemy.data == null or enemy.data.xp_reward <= 0:
		return null
	return place(enemy.data.xp_reward, enemy.global_position)


## Puts XP on the ground at a world position. Returns the gem now holding it.
func place(amount: int, world_position: Vector2) -> XpGem:
	if amount <= 0 or gem_scene == null:
		return null
	_forget_gone_gems()
	if _gems.size() >= max_gems and not _gems.is_empty():
		_gems[0].add_value(amount)
		return _gems[0]
	var root := drop_root if drop_root != null else get_parent()
	var gem := gem_scene.instantiate() as XpGem
	root.add_child(gem)
	gem.setup(amount)
	gem.global_position = world_position
	_gems.append(gem)
	return gem


func gem_count() -> int:
	_forget_gone_gems()
	return _gems.size()


func _forget_gone_gems() -> void:
	for i in range(_gems.size() - 1, -1, -1):
		if not is_instance_valid(_gems[i]) or _gems[i].is_queued_for_deletion():
			_gems.remove_at(i)
