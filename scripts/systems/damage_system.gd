class_name DamageSystem
extends RefCounted

## All damage passes through here so elemental rules live in one place.


## The one elemental calculation. Each attacker element is compared with the defender's, and the
## hit uses the best match (the first element wins a tie). A strong multiplier above neutral has
## its bonus scaled by `vulnerability_scale` (never below 0). A resisted multiplier becomes
## neutral if `ignores_resistance`. An empty list, NO_ELEMENT and unknown elements are neutral.
static func resolve(
	base_damage: float,
	attacker_elements: Array,
	defender_element: int,
	vulnerability_scale: float = 1.0,
	ignores_resistance: bool = false,
	table: ElementTable = null,
) -> HitResult:
	var element_table := table if table != null else ElementTable.default_table()
	var scale := maxf(vulnerability_scale, 0.0)
	var elements: Array = attacker_elements if not attacker_elements.is_empty() else [SpellData.NO_ELEMENT]
	var best_multiplier := -INF
	var best_effect: int = ElementTable.Effect.NEUTRAL
	for attacker in elements:
		var hit_effect: int = element_table.effect(attacker, defender_element)
		var multiplier := element_table.multiplier(attacker, defender_element)
		if hit_effect == ElementTable.Effect.VULNERABLE and multiplier > element_table.neutral_multiplier:
			multiplier = element_table.neutral_multiplier + (multiplier - element_table.neutral_multiplier) * scale
		elif hit_effect == ElementTable.Effect.RESISTED and ignores_resistance:
			multiplier = element_table.neutral_multiplier
			hit_effect = ElementTable.Effect.NEUTRAL
		if multiplier > best_multiplier:
			best_multiplier = multiplier
			best_effect = hit_effect
	var result := HitResult.new()
	result.amount = maxf(base_damage * best_multiplier, 0.0)
	result.effect = best_effect
	return result


static func calculate(
	base_damage: float,
	attacker_element: int = SpellData.NO_ELEMENT,
	defender_element: int = SpellData.NO_ELEMENT,
	table: ElementTable = null,
) -> float:
	return resolve(base_damage, [attacker_element], defender_element, 1.0, false, table).amount


static func effect(
	attacker_element: int,
	defender_element: int,
	table: ElementTable = null,
) -> ElementTable.Effect:
	return resolve(0.0, [attacker_element], defender_element, 1.0, false, table).effect as ElementTable.Effect
