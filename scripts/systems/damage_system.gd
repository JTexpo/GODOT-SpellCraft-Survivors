class_name DamageSystem
extends RefCounted

## All damage passes through here so elemental rules live in one place.


static func calculate(
	base_damage: float,
	attacker_element: int = SpellData.NO_ELEMENT,
	defender_element: int = SpellData.NO_ELEMENT,
	table: ElementTable = null,
) -> float:
	var element_table := table if table != null else ElementTable.default_table()
	return maxf(base_damage * element_table.multiplier(attacker_element, defender_element), 0.0)
