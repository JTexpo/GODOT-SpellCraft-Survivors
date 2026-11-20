class_name PlayerProfile
extends RefCounted
## What persists between runs: total XP (the level is computed from it, so the two can never
## disagree) and the buff chosen for each starting-spell buff reward, keyed by the reward's level.

var total_xp: int = 0
## Reward level (int) to buff scroll id (StringName).
var buff_picks: Dictionary = {}


## Null if the data is missing a field, has a wrongly typed one, or is from another save version.
static func from_dict(data: Dictionary) -> PlayerProfile:
	if not _is_whole_number(data.get("version")) or int(data["version"]) != SaveGame.VERSION:
		return null
	if not _is_whole_number(data.get("total_xp")) or int(data["total_xp"]) < 0:
		return null
	var picks = data.get("buff_picks")
	if not picks is Dictionary:
		return null
	var profile := PlayerProfile.new()
	profile.total_xp = int(data["total_xp"])
	for key in picks:
		if not key is String or not key.is_valid_int() or not picks[key] is String:
			return null
		profile.buff_picks[int(key)] = StringName(picks[key])
	return profile


## JSON gives every number as a float, so a whole-number float counts.
static func _is_whole_number(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_equal_approx(value, roundf(value))


func level(track: LevelTrack) -> int:
	return track.level_for_xp(total_xp)


func add_xp(amount: int) -> void:
	if amount > 0:
		total_xp += amount


func set_pick(level_number: int, buff_id: StringName) -> void:
	buff_picks[level_number] = buff_id


## &"" when nothing was picked for that reward level.
func pick(level_number: int) -> StringName:
	return buff_picks.get(level_number, &"")


func to_dict() -> Dictionary:
	var picks := {}
	for level_number in buff_picks:
		picks[str(level_number)] = str(buff_picks[level_number])
	return {"version": SaveGame.VERSION, "total_xp": total_xp, "buff_picks": picks}
