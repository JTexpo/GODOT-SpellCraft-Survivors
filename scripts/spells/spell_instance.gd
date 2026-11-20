class_name SpellInstance
extends RefCounted
## An equipped spell at runtime. Owns its own mana and cast cooldown, so two instances built
## from one SpellData never share mana. Mana never regenerates: only restore_mana() refills it.

signal mana_changed(current: float, maximum: float)

var data: SpellData
var current_mana: float
var cooldown_left: float = 0.0
## A fraction of the spell's own pool added by the wizard's level (0.15 is +15%). It lives here and
## not on the shared SpellData, so two instances of one spell never share it.
var max_mana_bonus: float = 0.0


func _init(spell_data: SpellData) -> void:
	data = spell_data
	current_mana = spell_data.max_mana


func has_mana() -> bool:
	return current_mana >= data.mana_cost


func can_cast() -> bool:
	return has_mana() and cooldown_left <= 0.0


func cast() -> bool:
	if not can_cast():
		return false
	current_mana -= data.mana_cost
	cooldown_left = data.cast_interval
	mana_changed.emit(current_mana, max_mana())
	return true


func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


## A negative amount refills the pool completely.
func restore_mana(amount: float = -1.0) -> void:
	if amount < 0.0:
		current_mana = max_mana()
	else:
		current_mana = minf(current_mana + amount, max_mana())
	mana_changed.emit(current_mana, max_mana())


func mana_ratio() -> float:
	return current_mana / max_mana() if max_mana() > 0.0 else 0.0


## The pool, including the level's bonus.
func max_mana() -> float:
	return data.max_mana * (1.0 + max_mana_bonus)


## When the bonus rises, current mana rises by the pool's increase. When it falls, current is clamped.
func set_max_mana_bonus(bonus: float) -> void:
	var before := max_mana()
	max_mana_bonus = bonus
	current_mana = clampf(current_mana + (max_mana() - before), 0.0, max_mana())
	mana_changed.emit(current_mana, max_mana())
