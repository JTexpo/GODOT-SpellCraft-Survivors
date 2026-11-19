class_name CraftingRules
extends Resource
## The numbers crafting uses that belong to no single scroll: the range options.

const DEFAULT_PATH := "res://resources/crafting/crafting_rules.tres"

@export var range_options: Array[RangeOption] = []


static func default_rules() -> CraftingRules:
	return load(DEFAULT_PATH) as CraftingRules


## Null if the index is out of range.
func option(index: int) -> RangeOption:
	if index < 0 or index >= range_options.size():
		return null
	return range_options[index]


## The option with a range scale of 1.0 (the default choice), or the first one.
func normal_index() -> int:
	for i in range_options.size():
		if is_equal_approx(range_options[i].range_scale, 1.0):
			return i
	return 0
