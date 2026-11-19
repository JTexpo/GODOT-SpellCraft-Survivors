class_name CraftingRequest
extends RefCounted
## What the player asked the Lectern to craft: which scrolls, which range, which slot.

var base: ScrollData
var area: ScrollData
## Index into CraftingRules.range_options.
var option_index: int = 0
## Buff scrolls. Locked until Sprint 7, so any entry makes the request invalid.
var buffs: Array[ScrollData] = []
var slot_index: int = 0
