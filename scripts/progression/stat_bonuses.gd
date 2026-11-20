class_name StatBonuses
extends RefCounted
## The stat rewards a level adds up to, as fractions of the base value. One object, one path: the
## Player turns it into speed, health and spell mana, and later equipment feeds the same stats.

enum Stat { SPEED, HEALTH, SPELL_MANA }

var _fractions: Dictionary = {}


## Every reward up to `level` of the matching kind, summed.
static func for_level(track: LevelTrack, level: int) -> StatBonuses:
	var bonuses := StatBonuses.new()
	bonuses.add(Stat.SPEED, track.stat_sum(LevelReward.Kind.SPEED, level))
	bonuses.add(Stat.HEALTH, track.stat_sum(LevelReward.Kind.HEALTH, level))
	bonuses.add(Stat.SPELL_MANA, track.stat_sum(LevelReward.Kind.MANA, level))
	return bonuses


func add(stat: Stat, fraction: float) -> void:
	_fractions[stat] = fraction(stat) + fraction


## 0.0 for a stat nothing was added to.
func fraction(stat: Stat) -> float:
	return float(_fractions.get(stat, 0.0))


func multiplier(stat: Stat) -> float:
	return 1.0 + fraction(stat)
