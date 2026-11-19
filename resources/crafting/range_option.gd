class_name RangeOption
extends Resource
## One choice on the crafting screen: how far the Area reaches and what that costs in mana.

@export var label: String
@export var range_scale: float = 1.0
## Multiplies the spell's mana cost per cast. A longer range costs more, a shorter one less.
@export var cost_multiplier: float = 1.0
