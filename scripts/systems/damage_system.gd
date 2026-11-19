class_name DamageSystem
extends RefCounted

## All damage passes through here so elemental rules can be added in one place later.


static func calculate(base_damage: float) -> float:
	return maxf(base_damage, 0.0)
