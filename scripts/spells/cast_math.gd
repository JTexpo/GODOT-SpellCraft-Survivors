class_name CastMath
extends RefCounted
## The formulas that turn equipment and level bonuses into what a cast does. The loadout uses them
## when it casts and the crafting preview uses them to show the same numbers. Everything takes
## fractions (0.25 is +25%), and nothing here touches a spell.

const MIN_INTERVAL := 0.05
const MIN_DAMAGE_SCALE := 0.1
## Casting speed can never push the divisor below this, so a huge slowdown stays finite.
const MIN_SPEED_FACTOR := 0.1


## (1 + spell damage) times the mean over the spell's elements of (1 + that element's bonus), never
## below MIN_DAMAGE_SCALE. A spell with no element uses only the spell damage bonus.
static func damage_scale(elements: Array, bonuses: StatBonuses) -> float:
	var scale := 1.0 + bonuses.fraction(StatBonuses.Stat.SPELL_DAMAGE)
	var counted := 0
	var element_total := 0.0
	for element in elements:
		var stat := StatBonuses.damage_stat(element)
		if stat < 0:
			continue
		element_total += 1.0 + bonuses.fraction(stat)
		counted += 1
	if counted > 0:
		scale *= element_total / counted
	return maxf(scale, MIN_DAMAGE_SCALE)


## `base / (1 + cast speed)`, never below the floor (or below `base` itself when that is already
## shorter) and finite for any speed.
static func interval(base: float, cast_speed: float) -> float:
	var result := base / maxf(1.0 + cast_speed, MIN_SPEED_FACTOR)
	return maxf(result, minf(MIN_INTERVAL, base))


static func pool(base: float, spell_mana: float) -> float:
	return base * (1.0 + spell_mana)


## A chance stat held between 0 and 1.
static func chance(bonuses: StatBonuses, stat: StatBonuses.Stat) -> float:
	return clampf(bonuses.fraction(stat), 0.0, 1.0)
