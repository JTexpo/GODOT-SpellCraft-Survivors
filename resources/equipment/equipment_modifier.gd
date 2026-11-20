class_name EquipmentModifier
extends Resource
## One bonus an item gives: a stat and how much, as a fraction (0.15 is +15%, -0.15 is -15%).

@export var stat: StatBonuses.Stat = StatBonuses.Stat.SPEED
@export var amount: float = 0.0
