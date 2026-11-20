class_name CraftingSession
extends RefCounted
## What the player has picked on the crafting workbench so far, and what that would make. It has no
## UI: the screen shows it and calls into it. All rules are in SpellBuilder and CraftingSystem,
## so this only remembers choices, asks them for previews and tells the screen what to show.

signal changed

var rules: CraftingRules
## Chosen Base scrolls, oldest first. At most max_bases().
var bases: Array[ScrollData] = []
## Chosen Buff scrolls. A repeated scroll is a stack.
var buffs: Array[ScrollData] = []
var area: ScrollData
var option_index: int
var slot_index: int

var _inventory: ScrollInventory
var _loadout: SpellLoadout


func _init(crafting_rules: CraftingRules, inventory: ScrollInventory, loadout: SpellLoadout) -> void:
	rules = crafting_rules
	_inventory = inventory
	_loadout = loadout
	option_index = rules.normal_index()
	slot_index = _default_slot()


## One Base, plus one more for each Additional Base stack chosen.
func max_bases() -> int:
	var total := 1
	for buff in buffs:
		total += buff.buff.extra_bases
	return total


## Choosing a chosen Base clears it. Choosing a new one at the limit replaces the oldest choice.
func select_base(scroll: ScrollData) -> bool:
	if scroll == null or scroll.category != ScrollData.Category.BASE or not _inventory.has(scroll):
		return false
	if bases.has(scroll):
		bases.erase(scroll)
	else:
		while bases.size() >= max_bases():
			bases.pop_front()
		bases.append(scroll)
	changed.emit()
	return true


## Whether one more stack of this scroll can be added: it must be a Buff scroll with an effect, and
## the stacks cannot pass what the player owns or the buff's own cap.
func can_add_buff(scroll: ScrollData) -> bool:
	if scroll == null or scroll.category != ScrollData.Category.BUFF or scroll.buff == null:
		return false
	var stacks := buff_stacks(scroll)
	if stacks >= _inventory.count(scroll):
		return false
	return scroll.buff.max_stacks <= 0 or stacks < scroll.buff.max_stacks


func add_buff(scroll: ScrollData) -> bool:
	if not can_add_buff(scroll):
		return false
	buffs.append(scroll)
	changed.emit()
	return true


## Removes one stack, then drops the newest Base choices that no longer fit.
func remove_buff(scroll: ScrollData) -> bool:
	var index := buffs.rfind(scroll)
	if index < 0:
		return false
	buffs.remove_at(index)
	_trim_bases()
	changed.emit()
	return true


func buff_stacks(scroll: ScrollData) -> int:
	return buffs.count(scroll)


func select_area(scroll: ScrollData) -> bool:
	if scroll == null or scroll.category != ScrollData.Category.AREA or not _inventory.has(scroll):
		return false
	area = null if scroll == area else scroll
	changed.emit()
	return true


func select_range(index: int) -> bool:
	if rules.option(index) == null:
		return false
	option_index = index
	changed.emit()
	return true


func select_slot(index: int) -> bool:
	if not _loadout.is_unlocked(index):
		return false
	slot_index = index
	changed.emit()
	return true


func owned_bases() -> Array[ScrollData]:
	return _inventory.by_category(ScrollData.Category.BASE)


func owned_areas() -> Array[ScrollData]:
	return _inventory.by_category(ScrollData.Category.AREA)


func owned_buffs() -> Array[ScrollData]:
	return _inventory.by_category(ScrollData.Category.BUFF)


func request() -> CraftingRequest:
	var made := CraftingRequest.new()
	made.bases = bases.duplicate()
	made.buffs = buffs.duplicate()
	made.area = area
	made.option_index = option_index
	made.slot_index = slot_index
	return made


func preview() -> SpellData:
	return CraftingSystem.preview(request(), rules)


func validation() -> CraftingResult:
	return CraftingSystem.validate(request(), rules, _inventory, _loadout)


func can_confirm() -> bool:
	return validation().ok


## Crafts, and drops a chosen scroll the player no longer has enough of. Buffs are trimmed to the
## owned count first, because that changes how many Bases fit.
func confirm() -> CraftingResult:
	var result := CraftingSystem.craft(request(), rules, _inventory, _loadout)
	if result.ok:
		for scroll in buffs.duplicate():
			if buff_stacks(scroll) > _inventory.count(scroll):
				buffs.remove_at(buffs.rfind(scroll))
		bases = bases.filter(func(scroll: ScrollData) -> bool: return _inventory.has(scroll))
		_trim_bases()
		if area != null and not _inventory.has(area):
			area = null
		changed.emit()
	return result


## The numbers of the spell the choices would make. Empty when there is nothing to preview.
func new_stats() -> Dictionary:
	var spell := preview()
	return SpellBuilder.describe(spell) if spell != null else {}


## The numbers of the spell now in the target slot. Empty for an empty slot.
func current_stats() -> Dictionary:
	var instance := _loadout.slots[slot_index] if slot_index < _loadout.slots.size() else null
	return SpellBuilder.describe(instance.data) if instance != null else {}


## Plain-words costs of the chosen buffs. Empty with no buffs or when the spell cannot be built.
func drawbacks() -> Array[String]:
	var lines: Array[String] = []
	if buffs.is_empty():
		return lines
	var buffed := preview()
	var plain := SpellBuilder.build(bases, area, rules.option(option_index))
	if buffed == null or plain == null:
		return lines
	var multiplier := snappedf(buffed.mana_cost / plain.mana_cost, 0.1) if plain.mana_cost > 0.0 else 1.0
	lines.append("Buffs: costs %.1fx per cast, %d casts become %d." % [
		multiplier,
		SpellBuilder.whole_casts(plain),
		SpellBuilder.whole_casts(buffed),
	])
	if not SpellBuilder.can_cast(buffed):
		lines.append(CraftingSystem.REASON_TOO_COSTLY)
	return lines


func replace_note() -> String:
	var instance := _loadout.slots[slot_index] if slot_index < _loadout.slots.size() else null
	if instance == null:
		return "Empty slot"
	if not instance.has_mana():
		return "Replaces %s (empty)" % instance.data.display_name
	return "Replaces %s (%d / %d mana left)" % [
		instance.data.display_name, roundi(instance.current_mana), roundi(instance.data.max_mana),
	]


## Why the craft cannot be confirmed yet, or an empty string when it can.
func message() -> String:
	return validation().reason


func _trim_bases() -> void:
	while bases.size() > max_bases():
		bases.pop_back()


func _default_slot() -> int:
	if _loadout.is_unlocked(_loadout.selected_index):
		return _loadout.selected_index
	for i in SpellLoadout.SLOT_COUNT:
		if _loadout.is_unlocked(i):
			return i
	return 0
