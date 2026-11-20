class_name StartingBuffs
extends RefCounted
## The buffs a starting spell is given by level rewards. A `RunBuffs` keeps one pick per buff reward
## for this run only (nothing is saved), and a reward without a pick is "unresolved": a random one is
## rolled and a chosen one is asked for on the pick screen, at every run start. Which buffs are on
## offer is data (`LevelTrack.buff_pool`), and a buff already at its stack cap on that spell this run
## is left out.


## The reward levels up to `level` of this kind that have no pick yet, lowest first.
static func unresolved_levels(buffs: RunBuffs, track: LevelTrack, level: int, kind: LevelReward.Kind) -> Array[int]:
	var levels: Array[int] = []
	for reached in range(2, mini(level, track.max_level()) + 1):
		if track.reward_for_level(reached).kind == kind and buffs.pick(reached) == &"":
			levels.append(reached)
	return levels


## Rolls every unresolved RANDOM_BUFF reward up to `level`, stores each in `buffs` and returns the
## levels it rolled. A reward with nothing left to offer stays unresolved and is not returned.
static func roll_random(buffs: RunBuffs, track: LevelTrack, level: int, rng: RandomNumberGenerator) -> Array[int]:
	var rolled: Array[int] = []
	for reached in unresolved_levels(buffs, track, level, LevelReward.Kind.RANDOM_BUFF):
		var options := options_for(buffs, track, reached)
		if options.is_empty():
			continue
		buffs.set_pick(reached, options[rng.randi() % options.size()].id)
		rolled.append(reached)
	return rolled


## The pool's buffs that this reward's spell can still take. Empty for a level with no buff reward.
static func options_for(buffs: RunBuffs, track: LevelTrack, reward_level: int) -> Array[ScrollData]:
	var options: Array[ScrollData] = []
	var reward := track.reward_for_level(reward_level)
	if reward == null or not _is_buff_reward(reward):
		return options
	var taken := {}
	for picked_level in buffs.picks:
		var other := track.reward_for_level(picked_level)
		if other != null and _is_buff_reward(other) and other.spell_index == reward.spell_index:
			taken[buffs.picks[picked_level]] = int(taken.get(buffs.picks[picked_level], 0)) + 1
	for scroll in track.buff_pool:
		var cap := scroll.buff.max_stacks
		if cap == 0 or int(taken.get(scroll.id, 0)) < cap:
			options.append(scroll)
	return options


## The buffs picked for one starting spell by rewards up to `level`, in level order. Ids that are no
## longer in the pool are skipped.
static func buffs_for_spell(buffs: RunBuffs, track: LevelTrack, level: int, spell_index: int) -> Array[ScrollData]:
	var result: Array[ScrollData] = []
	for reached in range(2, mini(level, track.max_level()) + 1):
		var reward := track.reward_for_level(reached)
		if not _is_buff_reward(reward) or reward.spell_index != spell_index:
			continue
		var scroll := find_scroll(track, buffs.pick(reached))
		if scroll != null:
			result.append(scroll)
	return result


static func _is_buff_reward(reward: LevelReward) -> bool:
	return reward.kind == LevelReward.Kind.RANDOM_BUFF or reward.kind == LevelReward.Kind.CHOSEN_BUFF


## The pool's scroll with this id, or null (an empty or unknown id).
static func find_scroll(track: LevelTrack, buff_id: StringName) -> ScrollData:
	if buff_id == &"":
		return null
	for scroll in track.buff_pool:
		if scroll.id == buff_id:
			return scroll
	return null
