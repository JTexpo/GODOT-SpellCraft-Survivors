class_name PlayerProfile
extends RefCounted
## What persists between runs: total XP (the level is computed from it, so the two can never
## disagree). A `buff_picks` field in an old save is ignored.

var total_xp: int = 0


## Null if the data is missing a field, has a wrongly typed one, or is from another save version.
static func from_dict(data: Dictionary) -> PlayerProfile:
	if not _is_whole_number(data.get("version")) or int(data["version"]) != SaveGame.VERSION:
		return null
	if not _is_whole_number(data.get("total_xp")) or int(data["total_xp"]) < 0:
		return null
	var profile := PlayerProfile.new()
	profile.total_xp = int(data["total_xp"])
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


func to_dict() -> Dictionary:
	return {"version": SaveGame.VERSION, "total_xp": total_xp}
