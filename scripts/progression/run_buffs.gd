class_name RunBuffs
extends RefCounted
## The buffs the starting spells were given for this run only, keyed by the level of the reward that
## gave them. Nothing here is saved: a chosen buff is picked and a random buff re-rolled at every run
## start (player feedback, Sprint 9).

## Reward level (int) to buff scroll id (StringName).
var picks: Dictionary = {}


func set_pick(level_number: int, buff_id: StringName) -> void:
	picks[level_number] = buff_id


## &"" when nothing was given for that reward level.
func pick(level_number: int) -> StringName:
	return picks.get(level_number, &"")
