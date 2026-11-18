class_name SpellData
extends Resource

enum Element { FIRE, THUNDER, LAND, SEA }
enum AreaType { LINE, CONE, AREA, MISSILE }

@export var id: StringName
@export var display_name: String
@export var elements: Array[Element] = []
@export var area: AreaType = AreaType.MISSILE
