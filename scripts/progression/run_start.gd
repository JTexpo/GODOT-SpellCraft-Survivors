class_name RunStart
extends RefCounted
## Sets a run up from the saved profile: the stat bonuses, the unlocked slots and the starting spells
## with the buffs their rewards gave. It never rolls or asks for a pick (Main does that first), and
## running it again gives the same state, so a restart can never apply a bonus twice.


static func prepare(player: Player, profile: PlayerProfile, track: LevelTrack) -> void:
	var level := profile.level(track)
	# Bonuses first, so every spell equipped below starts with the level's mana bonus.
	player.apply_stat_bonuses(StatBonuses.for_level(track, level), false)
	var loadout := player.loadout
	loadout.unlocked_slots = track.slot_count(level)
	if not loadout.starting_spells.is_empty():
		_equip(loadout, 0, loadout.starting_spells[0], StartingBuffs.buffs_for_spell(profile, track, level, 0))
	for reached in range(2, mini(level, track.max_level()) + 1):
		var reward := track.reward_for_level(reached)
		if reward.kind == LevelReward.Kind.SECOND_SPELL:
			_equip(loadout, 1, reward.spell, StartingBuffs.buffs_for_spell(profile, track, level, 1))


static func _equip(loadout: SpellLoadout, slot: int, spell: SpellData, buffs: Array[ScrollData]) -> void:
	var built := SpellBuilder.with_buffs(spell, buffs)
	if built != null:
		loadout.equip(slot, built)
