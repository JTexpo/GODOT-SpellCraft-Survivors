class_name PlayerProfile
extends RefCounted
## What persists between runs: total XP (the level is computed from it, so the two can never
## disagree), Gold, the equipment the player owns and what is equipped in each slot. A `buff_picks`
## field in an old save is ignored.

## The largest XP or Gold a save accepts (2^53, the last whole number a JSON float holds exactly).
const MAX_VALUE := 9007199254740992
const SLOT_COUNT := 3

var total_xp: int = 0
var gold: int = 0
var owned: Array[StringName] = []
## Slot (int, 0 to SLOT_COUNT - 1) to equipment id (StringName).
var equipped: Dictionary = {}


## Null if a field is missing (version and total_xp), has a wrongly typed or out-of-range value, or
## the file is from another save version. Optional fields (gold, owned, equipped) default when absent.
static func from_dict(data: Dictionary) -> PlayerProfile:
	if not _is_whole_in_range(data.get("version")) or int(data["version"]) != SaveGame.VERSION:
		return null
	if not _is_whole_in_range(data.get("total_xp")):
		return null
	var profile := PlayerProfile.new()
	profile.total_xp = int(data["total_xp"])
	if data.has("gold"):
		if not _is_whole_in_range(data["gold"]):
			return null
		profile.gold = int(data["gold"])
	if data.has("owned"):
		if not data["owned"] is Array:
			return null
		for id in data["owned"]:
			if not id is String:
				return null
			profile.grant(StringName(id))
	if data.has("equipped"):
		if not data["equipped"] is Dictionary:
			return null
		for key in data["equipped"]:
			if not key is String or not key.is_valid_int() or not data["equipped"][key] is String:
				return null
			var slot := int(key)
			if slot < 0 or slot >= SLOT_COUNT or str(slot) != key:
				return null
			var id := StringName(data["equipped"][key])
			if profile.owns(id):
				profile.equipped[slot] = id
	return profile


## JSON gives every number as a float, so a whole-number float counts. Rejects anything that is not
## exactly whole, below 0 or above MAX_VALUE (compared as a float, so 1e19 cannot overflow an int).
static func _is_whole_in_range(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return number == floorf(number) and number >= 0.0 and number <= float(MAX_VALUE)


func level(track: LevelTrack) -> int:
	return track.level_for_xp(total_xp)


func add_xp(amount: int) -> void:
	total_xp = _added(total_xp, amount)


func add_gold(amount: int) -> void:
	gold = _added(gold, amount)


## Spends Gold. False, with nothing changed, if the amount is not positive or more than the player has.
func spend_gold(amount: int) -> bool:
	if amount <= 0 or amount > gold:
		return false
	gold -= amount
	return true


func owns(id: StringName) -> bool:
	return owned.has(id)


## Adds an item to the owned list. Never adds one twice.
func grant(id: StringName) -> void:
	if not owned.has(id):
		owned.append(id)


func equip(slot: int, id: StringName) -> void:
	equipped[slot] = id


func unequip(slot: int) -> void:
	equipped.erase(slot)


## &"" when nothing is equipped in that slot.
func equipped_id(slot: int) -> StringName:
	return equipped.get(slot, &"")


func to_dict() -> Dictionary:
	var owned_ids: Array[String] = []
	for id in owned:
		owned_ids.append(str(id))
	var equipped_ids := {}
	for slot in equipped:
		equipped_ids[str(slot)] = str(equipped[slot])
	return {
		"version": SaveGame.VERSION,
		"total_xp": total_xp,
		"gold": gold,
		"owned": owned_ids,
		"equipped": equipped_ids,
	}


## `current + amount` held at MAX_VALUE, ignoring amounts at or below 0 (and safe from int overflow).
static func _added(current: int, amount: int) -> int:
	if amount <= 0:
		return current
	if amount >= MAX_VALUE - current:
		return MAX_VALUE
	return current + amount
