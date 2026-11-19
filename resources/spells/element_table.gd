class_name ElementTable
extends Resource
## Elemental damage multipliers. Fire > Land > Thunder > Sea > Fire.
## Each element is strong against the one it beats and weak against the one that beats it.

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


func multiplier(attacker: int, defender: int) -> float:
	if attacker == SpellData.NO_ELEMENT or defender == SpellData.NO_ELEMENT:
		return neutral_multiplier
	if BEATS.get(attacker) == defender:
		return strong_multiplier
	if BEATS.get(defender) == attacker:
		return weak_multiplier
	return neutral_multiplier
