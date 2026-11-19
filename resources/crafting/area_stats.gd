class_name AreaStats
extends Resource
## The baseline numbers of one Area, before a Base scroll's multipliers and the range option.
## Crafting turns these, a BaseModifiers and a RangeOption into a spell (see SpellBuilder).

@export var damage: float = 10.0
## Seconds between casts.
@export var cast_interval: float = 0.35
@export var mana_cost: float = 1.0
@export var max_mana: float = 100.0
## Missile and Wave only.
@export var projectile_speed: float = 220.0
@export var knockback: float = 0.0
