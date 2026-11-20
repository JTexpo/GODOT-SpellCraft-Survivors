class_name LevelReward
extends Resource
## What one level gives. Stat rewards carry a fraction of the base value in `amount`. Buff rewards
## say which starting spell they are for in `spell_index`. A second-spell reward carries the spell.

enum Kind { SPEED, HEALTH, MANA, SLOT, RANDOM_BUFF, CHOSEN_BUFF, SECOND_SPELL }

@export var kind: Kind = Kind.SPEED
## A fraction of the base value (0.08 is +8%). Only the stat kinds use it.
@export var amount: float = 0.0
## 0 is the first starting spell, 1 the second. Only the buff kinds use it.
@export var spell_index: int = 0
## The spell a SECOND_SPELL reward gives.
@export var spell: SpellData
## The line the level-up toast shows.
@export var description: String = ""
