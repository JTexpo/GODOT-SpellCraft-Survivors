class_name SpellInstance
extends RefCounted
## An equipped spell at runtime. Owns its own mana and cast cooldown, so two instances built
## from one SpellData never share mana. Mana never regenerates: only restore_mana() refills it.

signal mana_changed(current: float, maximum: float)

var data: SpellData
var current_mana: float
var cooldown_left: float = 0.0


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
	mana_changed.emit(current_mana, data.max_mana)
	return true


func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


## A negative amount refills the pool completely.
func restore_mana(amount: float = -1.0) -> void:
	if amount < 0.0:
		current_mana = data.max_mana
	else:
		current_mana = minf(current_mana + amount, data.max_mana)
	mana_changed.emit(current_mana, data.max_mana)


func mana_ratio() -> float:
	return current_mana / data.max_mana if data.max_mana > 0.0 else 0.0
