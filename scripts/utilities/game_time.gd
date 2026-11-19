class_name GameTime
extends RefCounted
## A millisecond clock that stands still while the game is paused. Gameplay timers that must not
## run during a pause (hit cooldowns) read this instead of the real-time clock. The state is
## static because there are no autoloads, so Main resets it when a run starts.

static var _frozen_since: int = -1
static var _frozen_total: int = 0


static func now_msec() -> int:
	if _frozen_since >= 0:
		return _frozen_since - _frozen_total
	return Time.get_ticks_msec() - _frozen_total


static func freeze() -> void:
	if _frozen_since < 0:
		_frozen_since = Time.get_ticks_msec()


static func unfreeze() -> void:
	if _frozen_since >= 0:
		_frozen_total += Time.get_ticks_msec() - _frozen_since
		_frozen_since = -1


static func is_frozen() -> bool:
	return _frozen_since >= 0


static func reset() -> void:
	_frozen_since = -1
	_frozen_total = 0
