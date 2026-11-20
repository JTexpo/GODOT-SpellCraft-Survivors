class_name ProfileSaver
extends Node
## Writes the profile to disk: right away on request, every `interval` seconds while something
## changed, and when the game is closed, loses focus or is paused (browsers and phones don't always
## send a close notice, so the periodic save is what covers them). An empty path means it never saves.

@export var interval: float = 10.0

var _profile: PlayerProfile
var _path: String = ""
var _dirty: bool = false
var _since_dirty: float = 0.0


func _process(delta: float) -> void:
	tick(delta)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if _dirty:
			save_now()


func bind(profile: PlayerProfile, path: String) -> void:
	_profile = profile
	_path = path
	_dirty = false


## Notes that the profile changed since the last save. Does nothing without a path.
func mark_dirty() -> void:
	if _path.is_empty():
		return
	if not _dirty:
		_since_dirty = 0.0
	_dirty = true


## Saves now. The dirty flag clears only if the write worked, so a failure is tried again later.
func save_now() -> bool:
	if _profile == null or _path.is_empty():
		return false
	if not SaveGame.save_profile(_profile, _path):
		return false
	_dirty = false
	return true


func is_dirty() -> bool:
	return _dirty


func tick(delta: float) -> void:
	if not _dirty:
		return
	_since_dirty += delta
	if _since_dirty >= interval:
		_since_dirty = 0.0
		save_now()
