class_name SpellData
extends Resource
## Static spell configuration. The equipped runtime object, with its own mana, is SpellInstance.

enum Element { FIRE, THUNDER, LAND, SEA }
enum AreaType { LINE, CONE, AREA, MISSILE }

## Stands for "no element" wherever an element is passed as a plain int.
const NO_ELEMENT := -1

@export var id: StringName
@export var display_name: String
@export var elements: Array[Element] = []
@export var area: AreaType = AreaType.MISSILE
@export var max_mana: float = 40.0
@export var mana_cost: float = 1.0
@export var damage: float = 10.0
## Seconds between casts.
@export var cast_interval: float = 0.35
@export var projectile_speed: float = 220.0
@export var projectile_lifetime: float = 1.2
@export var knockback: float = 0.0
## Enemies one projectile can hit before it is freed.
@export var max_hits: int = 1
@export var color: Color = Color.WHITE
@export var projectile_scene: PackedScene


func primary_element() -> int:
	return elements[0] if not elements.is_empty() else NO_ELEMENT
