class_name RunProgress
extends Node
## Turns collected XP into level-ups during a run. Stat and slot rewards apply the moment their level
## is reached. Rewards that change the starting spells (random buff, chosen buff, second spell) wait
## for the next run, so a level-up never interrupts a fight or touches a spell the player is using.

signal xp_changed(total_xp: int, level: int)
signal leveled_up(level: int, reward: LevelReward)

var profile: PlayerProfile
var track: LevelTrack
## XP collected since this run began.
var run_xp: int = 0
## Called with the reward's level when a RANDOM_BUFF reward is reached, so Main can roll and store it.
var starting_buffs_hook: Callable

var _player: Player


func bind(player: Player, run_profile: PlayerProfile, level_track: LevelTrack) -> void:
	_player = player
	profile = run_profile
	track = level_track


func level() -> int:
	return profile.level(track)


## Ignores amounts at or below 0 and a dead player. Several level-ups from one gain apply in order.
func add_xp(amount: int) -> void:
	if amount <= 0 or profile == null or _player.health.is_dead():
		return
	var before := level()
	profile.add_xp(amount)
	run_xp += amount
	xp_changed.emit(profile.total_xp, level())
	for reached in range(before + 1, level() + 1):
		var reward := track.reward_for_level(reached)
		_apply(reached, reward)
		leveled_up.emit(reached, reward)


func _apply(reached: int, reward: LevelReward) -> void:
	match reward.kind:
		LevelReward.Kind.SPEED, LevelReward.Kind.HEALTH, LevelReward.Kind.MANA:
			_player.apply_stat_bonuses(StatBonuses.for_level(track, reached), true)
		LevelReward.Kind.SLOT:
			_player.loadout.unlock_next()
		LevelReward.Kind.RANDOM_BUFF:
			if starting_buffs_hook.is_valid():
				starting_buffs_hook.call(reached)
		_:
			# CHOSEN_BUFF and SECOND_SPELL are applied at the start of the next run.
			pass
