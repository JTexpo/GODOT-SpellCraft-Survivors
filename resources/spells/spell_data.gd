class_name SpellData
extends Resource

enum Element { FIRE, THUNDER, LAND, SEA }
enum AreaType { LINE, CONE, AREA, MISSILE }

## Stands for "no element" wherever an element is passed as a plain int.
const NO_ELEMENT := -1

@export var id: StringName
@export var display_name: String
@export var elements: Array[Element] = []
@export var area: AreaType = AreaType.MISSILE
