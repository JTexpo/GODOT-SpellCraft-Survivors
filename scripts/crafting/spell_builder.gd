class_name SpellBuilder
extends RefCounted
## Turns Base scrolls, an Area scroll, a range option and Buff scrolls into a spell. This is the one
## place the crafting stat rules live, and it knows nothing about any screen or Lectern.
##
## Damage, interval, speed and knockback are the Area's baseline times the Base's multiplier. With
## several Bases (Additional Base) the multipliers are averaged, so a hybrid is not simply stronger.
## The mana cost is also times the range option's cost multiplier, and the mana pool is not, so a
## longer range costs more per cast and gives fewer casts from the same pool. Each Buff stack then
## applies its BuffEffect on top: multipliers multiply, bonuses add.


## Returns null if anything is missing or of the wrong kind.
static func build(bases: Array, area: ScrollData, option: RangeOption, buffs: Array = []) -> SpellData:
	if not _usable(bases, area, option) or not _buffs_usable(buffs):
		return null
	var stats := area.area_data.base_stats
	var spell := SpellData.new()
	spell.id = _spell_id(bases, area, option, buffs)
	spell.display_name = display_name(bases, area, option)
	var elements: Array[SpellData.Element] = []
	for base: ScrollData in bases:
		elements.append(base.element as SpellData.Element)
	spell.elements = elements
	spell.area_data = area.area_data
	spell.range_scale = option.range_scale
	spell.size_scale = 1.0
	var count := float(bases.size())
	var damage := 0.0
	var interval := 0.0
	var cost := 0.0
	var pool := 0.0
	var speed := 0.0
	var knockback := 0.0
	for base: ScrollData in bases:
		damage += base.modifiers.damage / count
		interval += base.modifiers.cast_interval / count
		cost += base.modifiers.mana_cost / count
		pool += base.modifiers.max_mana / count
		speed += base.modifiers.projectile_speed / count
		knockback += base.modifiers.knockback / count
	spell.damage = stats.damage * damage
	spell.cast_interval = stats.cast_interval * interval
	spell.mana_cost = stats.mana_cost * cost * option.cost_multiplier
	spell.max_mana = stats.max_mana * pool
	spell.projectile_speed = stats.projectile_speed * speed
	spell.knockback = stats.knockback * knockback
	spell.max_hits = 1
	spell.color = (bases[0] as ScrollData).color
	_apply_buffs(spell, buffs)
	return spell


## "Fire Missile", "Fire+Sea Missile", or "Fire Missile (Long)" when the range is not the normal one.
static func display_name(bases: Array, area: ScrollData, option: RangeOption) -> String:
	var names: Array[String] = []
	for base: ScrollData in bases:
		names.append(base.display_name)
	var text := "%s %s" % ["+".join(names), area.display_name]
	if option != null and not is_equal_approx(option.range_scale, 1.0):
		text += " (%s)" % option.label
	return text


## The numbers the crafting screen shows for a spell.
static func describe(spell: SpellData) -> Dictionary:
	var names: Array[String] = []
	for element in spell.elements:
		names.append(element_name(element))
	return {
		"name": spell.display_name,
		"damage": spell.damage,
		"interval": spell.cast_interval,
		"cost": spell.mana_cost,
		"pool": spell.max_mana,
		"casts": spell.max_mana / spell.mana_cost if spell.mana_cost > 0.0 else 0.0,
		"whole_casts": whole_casts(spell),
		"range": spell.effective_range(),
		"area": str(AreaData.AreaType.keys()[spell.area_type()]).capitalize(),
		"elements": "+".join(names),
		"copies": spell.copies,
		"vulnerability": spell.vulnerability_scale,
		"ignores_resistance": spell.ignores_resistance,
	}


## "Fire", "Thunder", ... or "None" for no element or an unknown value.
static func element_name(element: int) -> String:
	var names := SpellData.Element.keys()
	if element < 0 or element >= names.size():
		return "None"
	return str(names[element]).capitalize()


## How many casts the pool really pays for (a cast needs the full cost, so this rounds down).
static func whole_casts(spell: SpellData) -> int:
	return floori(spell.max_mana / spell.mana_cost + 1e-6) if spell.mana_cost > 0.0 else 0


## A spell whose cost is above its whole pool could never be cast once.
static func can_cast(spell: SpellData) -> bool:
	return spell != null and spell.mana_cost <= spell.max_mana


static func _apply_buffs(spell: SpellData, buffs: Array) -> void:
	var copies := 1
	var vulnerability := 1.0
	for buff: ScrollData in buffs:
		var effect := buff.buff
		spell.damage *= effect.damage_multiplier
		spell.max_mana *= effect.max_mana_multiplier
		spell.mana_cost *= effect.cost_multiplier
		vulnerability += effect.vulnerability_bonus
		spell.ignores_resistance = spell.ignores_resistance or effect.ignores_resistance
		copies += effect.extra_copies
		spell.buff_stacks[buff.id] = int(spell.buff_stacks.get(buff.id, 0)) + 1
	spell.copies = copies
	spell.vulnerability_scale = vulnerability


static func _usable(bases: Array, area: ScrollData, option: RangeOption) -> bool:
	if bases.is_empty() or area == null or option == null:
		return false
	for base: ScrollData in bases:
		if base == null or base.category != ScrollData.Category.BASE or base.modifiers == null:
			return false
	if area.category != ScrollData.Category.AREA or area.area_data == null:
		return false
	return area.area_data.base_stats != null


static func _buffs_usable(buffs: Array) -> bool:
	for buff: ScrollData in buffs:
		if buff == null or buff.category != ScrollData.Category.BUFF or buff.buff == null:
			return false
	return true


## Base and Area parts, the range, then each buff with its stack count, so any change in the recipe
## (including the order of the Bases) gives a different id.
static func _spell_id(bases: Array, area: ScrollData, option: RangeOption, buffs: Array) -> StringName:
	var parts: Array[String] = []
	for base: ScrollData in bases:
		parts.append(str(base.id).trim_prefix("base_"))
	parts.append(str(area.id).trim_prefix("area_"))
	parts.append(option.label.to_lower().replace(" ", "_"))
	var counts := {}
	for buff: ScrollData in buffs:
		counts[buff.id] = int(counts.get(buff.id, 0)) + 1
	var buff_ids := counts.keys()
	buff_ids.sort()
	for buff_id in buff_ids:
		parts.append("%s%d" % [str(buff_id).trim_prefix("buff_"), counts[buff_id]])
	return StringName("_".join(parts))
