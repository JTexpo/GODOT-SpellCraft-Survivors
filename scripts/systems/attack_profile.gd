class_name AttackProfile
extends RefCounted
## What an attack carries so the target's hurtbox can work out the damage: the elements of the
## spell, how much to scale a vulnerable hit's bonus, and whether resistance is ignored. A spell
## builds one once (SpellData.attack_profile), so a cast allocates nothing.

var elements: Array[int] = []
var vulnerability_scale: float = 1.0
var ignores_resistance: bool = false
