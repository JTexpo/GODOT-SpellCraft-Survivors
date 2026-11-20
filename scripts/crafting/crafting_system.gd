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
const REASON_BAD_BUFF := "That is not a usable buff scroll."
const REASON_STACK_CAP := "That buff cannot be stacked any further."
const REASON_TOO_MANY_BASES := "Add an Additional Base scroll to use a second element."
const REASON_DUPLICATE_ELEMENT := "A spell can't use the same element twice."
const REASON_LOCKED_SLOT := "That slot is locked."
const REASON_MISSING := "You don't have that scroll."
const REASON_CANNOT_BUILD := "That recipe can't be built."
const REASON_TOO_COSTLY := "Too costly: this spell could never cast."


## The spell the request would build, or null if the Base, Area or range is unusable. Ignores the
## inventory and the slot, so the screen can preview before the player owns everything.
static func preview(request: CraftingRequest, rules: CraftingRules) -> SpellData:
	return SpellBuilder.build(request.bases, request.area, rules.option(request.option_index), request.buffs)


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


## "Pick 2 more Base scrolls for your Additional Base."
static func need_bases_reason(count: int) -> String:
	return "Pick %d more Base scroll%s for your Additional Base." % [count, "" if count == 1 else "s"]


## Validates, and only if everything is fine removes every scroll the recipe uses (each Base, the
## Area and one per buff stack) and equips the new spell in the requested slot.
static func craft(
	request: CraftingRequest,
	rules: CraftingRules,
	inventory: ScrollInventory,
	loadout: SpellLoadout,
) -> CraftingResult:
	var result := validate(request, rules, inventory, loadout)
	if not result.ok:
		return result
	for scroll: ScrollData in _quantities(request):
		inventory.remove(scroll, _quantities(request)[scroll])
	loadout.equip(request.slot_index, result.spell)
	return result


static func _problem(
	request: CraftingRequest,
	rules: CraftingRules,
	inventory: ScrollInventory,
	loadout: SpellLoadout,
) -> String:
	if request.bases.is_empty():
		return REASON_NO_BASE
	if request.area == null:
		return REASON_NO_AREA
	for base in request.bases:
		if base == null or base.category != ScrollData.Category.BASE:
			return REASON_WRONG_BASE
	if request.area.category != ScrollData.Category.AREA:
		return REASON_WRONG_AREA
	if rules.option(request.option_index) == null:
		return REASON_BAD_RANGE
	var buff_problem := _buff_problem(request.buffs)
	if not buff_problem.is_empty():
		return buff_problem
	var wanted := 1 + _extra_bases(request.buffs)
	if request.bases.size() < wanted:
		return need_bases_reason(wanted - request.bases.size())
	if request.bases.size() > wanted:
		return REASON_TOO_MANY_BASES
	var seen := {}
	for base in request.bases:
		if seen.has(base.element):
			return REASON_DUPLICATE_ELEMENT
		seen[base.element] = true
	if not loadout.is_unlocked(request.slot_index):
		return REASON_LOCKED_SLOT
	var needed := _quantities(request)
	for scroll: ScrollData in needed:
		if not inventory.has(scroll, needed[scroll]):
			return REASON_MISSING
	# A scroll with missing data (no modifiers, no baseline) cannot make a spell. Refuse it here, or
	# craft() would consume the scrolls and equip nothing.
	var spell := preview(request, rules)
	if spell == null:
		return REASON_CANNOT_BUILD
	if not SpellBuilder.can_cast(spell):
		return REASON_TOO_COSTLY
	return ""


## Every buff entry must be a Buff scroll with an effect, and no buff may pass its stack cap.
static func _buff_problem(buffs: Array) -> String:
	var stacks := {}
	for buff: ScrollData in buffs:
		if buff == null or buff.category != ScrollData.Category.BUFF or buff.buff == null:
			return REASON_BAD_BUFF
		stacks[buff] = int(stacks.get(buff, 0)) + 1
		if buff.buff.max_stacks > 0 and stacks[buff] > buff.buff.max_stacks:
			return REASON_STACK_CAP
	return ""


static func _extra_bases(buffs: Array) -> int:
	var total := 0
	for buff: ScrollData in buffs:
		total += buff.buff.extra_bases
	return total


## Scroll to how many of it the request uses.
static func _quantities(request: CraftingRequest) -> Dictionary:
	var needed := {}
	var all: Array = []
	all.append_array(request.bases)
	all.append(request.area)
	all.append_array(request.buffs)
	for scroll: ScrollData in all:
		needed[scroll] = int(needed.get(scroll, 0)) + 1
	return needed
