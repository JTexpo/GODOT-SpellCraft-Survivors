class_name CraftingRequest
extends RefCounted
## What the player asked the Lectern to craft: which scrolls, which range, which slot.

## One Base scroll, plus one more for each Additional Base stack in `buffs`.
var bases: Array[ScrollData] = []
var area: ScrollData
## Index into CraftingRules.range_options.
var option_index: int = 0
## Buff scrolls. A repeated scroll is a stack.
var buffs: Array[ScrollData] = []
var slot_index: int = 0
