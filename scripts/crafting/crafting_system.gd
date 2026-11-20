class_name CraftingSystem
extends RefCounted
## Validates a crafting request, consumes the scrolls and equips the spell. It changes only the
## inventory and loadout it is given, and nothing is touched unless the whole request is valid, so
## a failed craft never costs the player a scroll.

const REASON_NO_BASE := "Choose a Base scroll."
const REASON_NO_AREA := "Choose an Area scroll."
const REASON_WRONG_BASE := "That is not a Base scroll."
const REASON_WRONG_AREA := "That is not an Area scroll."
const REASON_BAD_RANGE := "Choose a range."
const REASON_BUFFS_LOCKED := "Buffs are not available yet."
const REASON_LOCKED_SLOT := "That slot is locked."
const REASON_MISSING := "You don't have that scroll."
const REASON_CANNOT_BUILD := "That recipe can't be built."


## The spell the request would build, or null if the Base, Area or range is unusable. Ignores the
## inventory and the slot, so the screen can preview before the player owns everything.
static func preview(request: CraftingRequest, rules: CraftingRules) -> SpellData:
	return SpellBuilder.build([request.base], request.area, rules.option(request.option_index), request.buffs)


static func validate(
	request: CraftingRequest,
	rules: CraftingRules,
	inventory: ScrollInventory,
	loadout: SpellLoadout,
) -> CraftingResult:
	var result := CraftingResult.new()
	result.spell = preview(request, rules)
	result.reason = _problem(request, rules, inventory, loadout)
	result.ok = result.reason.is_empty()
	return result


## Validates, and only if everything is fine removes one Base and one Area scroll and equips the
## new spell in the requested slot.
static func craft(
	request: CraftingRequest,
	rules: CraftingRules,
	inventory: ScrollInventory,
	loadout: SpellLoadout,
) -> CraftingResult:
	var result := validate(request, rules, inventory, loadout)
	if not result.ok:
		return result
	inventory.remove(request.base)
	inventory.remove(request.area)
	loadout.equip(request.slot_index, result.spell)
	return result


static func _problem(
	request: CraftingRequest,
	rules: CraftingRules,
	inventory: ScrollInventory,
	loadout: SpellLoadout,
) -> String:
	if request.base == null:
		return REASON_NO_BASE
	if request.area == null:
		return REASON_NO_AREA
	if request.base.category != ScrollData.Category.BASE:
		return REASON_WRONG_BASE
	if request.area.category != ScrollData.Category.AREA:
		return REASON_WRONG_AREA
	if rules.option(request.option_index) == null:
		return REASON_BAD_RANGE
	if not request.buffs.is_empty():
		return REASON_BUFFS_LOCKED
	if not loadout.is_unlocked(request.slot_index):
		return REASON_LOCKED_SLOT
	if not inventory.has(request.base) or not inventory.has(request.area):
		return REASON_MISSING
	# A scroll with missing data (no modifiers, no baseline) cannot make a spell. Refuse it here, or
	# craft() would consume both scrolls and equip nothing.
	if preview(request, rules) == null:
		return REASON_CANNOT_BUILD
	return ""
