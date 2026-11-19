class_name SpellBuilder
extends RefCounted
## Turns a Base scroll, an Area scroll and a range option into a spell. This is the one place the
## crafting stat rules live, and it knows nothing about any screen or Lectern.
##
## Damage, interval, speed and knockback are the Area's baseline times the Base's multiplier. The
## mana cost is also times the range option's cost multiplier, and the mana pool is not, so a longer
## range costs more per cast and gives fewer casts from the same pool.


## Returns null if anything is missing or of the wrong kind.
static func build(base: ScrollData, area: ScrollData, option: RangeOption) -> SpellData:
	if not _usable(base, area, option):
		return null
	var stats := area.area_data.base_stats
	var mods := base.modifiers
	var spell := SpellData.new()
	spell.id = _spell_id(base, area, option)
	spell.display_name = display_name(base, area, option)
	spell.elements = [base.element] as Array[SpellData.Element]
	spell.area_data = area.area_data
	spell.range_scale = option.range_scale
	spell.size_scale = 1.0
	spell.damage = stats.damage * mods.damage
	spell.cast_interval = stats.cast_interval * mods.cast_interval
	spell.mana_cost = stats.mana_cost * mods.mana_cost * option.cost_multiplier
	spell.max_mana = stats.max_mana * mods.max_mana
	spell.projectile_speed = stats.projectile_speed * mods.projectile_speed
	spell.knockback = stats.knockback * mods.knockback
	spell.max_hits = 1
	spell.color = base.color
	return spell


## "Fire Missile", or "Fire Missile (Long)" when the range is not the normal one.
static func display_name(base: ScrollData, area: ScrollData, option: RangeOption) -> String:
	var text := "%s %s" % [base.display_name, area.display_name]
	if option != null and not is_equal_approx(option.range_scale, 1.0):
		text += " (%s)" % option.label
	return text


## The numbers the crafting screen shows for a spell.
static func describe(spell: SpellData) -> Dictionary:
	return {
		"name": spell.display_name,
		"damage": spell.damage,
		"interval": spell.cast_interval,
		"cost": spell.mana_cost,
		"pool": spell.max_mana,
		"casts": spell.max_mana / spell.mana_cost if spell.mana_cost > 0.0 else 0.0,
		"range": spell.effective_range(),
		"area": str(AreaData.AreaType.keys()[spell.area_type()]).capitalize(),
	}


static func _usable(base: ScrollData, area: ScrollData, option: RangeOption) -> bool:
	if base == null or area == null or option == null:
		return false
	if base.category != ScrollData.Category.BASE or base.modifiers == null:
		return false
	if area.category != ScrollData.Category.AREA or area.area_data == null:
		return false
	return area.area_data.base_stats != null


static func _spell_id(base: ScrollData, area: ScrollData, option: RangeOption) -> StringName:
	var label := option.label.to_lower().replace(" ", "_")
	var base_part := str(base.id).trim_prefix("base_")
	var area_part := str(area.id).trim_prefix("area_")
	return StringName("%s_%s_%s" % [base_part, area_part, label])
