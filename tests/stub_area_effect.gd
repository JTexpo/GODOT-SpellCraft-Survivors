class_name StubAreaEffect
extends AreaEffect
## Test double: records what the loadout launched it with.

var launched_spell: SpellData
var launched_origin: Vector2
var launched_direction: Vector2
var launched_target: Vector2


func launch(spell: SpellData, origin: Vector2, direction: Vector2, target: Vector2) -> void:
	launched_spell = spell
	launched_origin = origin
	launched_direction = direction
	launched_target = target
