class_name ElementTable
extends Resource
## Elemental damage multipliers. Fire > Land > Thunder > Sea > Fire.
## Each element is strong against the one it beats and weak against the one that beats it.

## How a hit went: VULNERABLE (the attacker's element beats the defender's), RESISTED (the
## defender's beats the attacker's) or NEUTRAL (same element, or either side has none).
enum Effect { NEUTRAL, VULNERABLE, RESISTED }

const DEFAULT_PATH := "res://resources/spells/element_table.tres"
const BEATS := {
	SpellData.Element.FIRE: SpellData.Element.LAND,
	SpellData.Element.LAND: SpellData.Element.THUNDER,
	SpellData.Element.THUNDER: SpellData.Element.SEA,
	SpellData.Element.SEA: SpellData.Element.FIRE,
}

@export var strong_multiplier: float = 1.5
@export var weak_multiplier: float = 0.5
@export var neutral_multiplier: float = 1.0


static func default_table() -> ElementTable:
	return load(DEFAULT_PATH) as ElementTable


func effect(attacker: int, defender: int) -> Effect:
	if attacker == SpellData.NO_ELEMENT or defender == SpellData.NO_ELEMENT:
		return Effect.NEUTRAL
	if BEATS.get(attacker) == defender:
		return Effect.VULNERABLE
	if BEATS.get(defender) == attacker:
		return Effect.RESISTED
	return Effect.NEUTRAL


func multiplier(attacker: int, defender: int) -> float:
	match effect(attacker, defender):
		Effect.VULNERABLE:
			return strong_multiplier
		Effect.RESISTED:
			return weak_multiplier
	return neutral_multiplier
