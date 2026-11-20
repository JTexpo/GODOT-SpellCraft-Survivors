class_name SpellData
extends Resource
## Static spell configuration. The equipped runtime object, with its own mana, is SpellInstance.

enum Element { FIRE, THUNDER, LAND, SEA }

## Stands for "no element" wherever an element is passed as a plain int.
const NO_ELEMENT := -1
## Floors for the effective range and size, so a crafted "shortest" spell never gets a zero-size shape.
const MIN_RANGE := 1.0
const MIN_SIZE := 0.1

@export var id: StringName
@export var display_name: String
@export var elements: Array[Element] = []
## The Area (Line, Cone, Area, Missile, Wave) that delivers this spell.
@export var area_data: AreaData
## Multiplies the Area's default range. Crafting changes this.
@export var range_scale: float = 1.0
## Multiplies the Area's default size (Line width, Cone angle, Area radius, Wave width, Missile scale).
@export var size_scale: float = 1.0
@export var max_mana: float = 40.0
@export var mana_cost: float = 1.0
@export var damage: float = 10.0
## Seconds between casts.
@export var cast_interval: float = 0.35
## Missile and Wave only.
@export var projectile_speed: float = 220.0
@export var knockback: float = 0.0
## Enemies one Missile can hit before it is freed.
@export var max_hits: int = 1
@export var color: Color = Color.WHITE
## Shots per cast (Duplicate Area makes it more than 1). Crafting sets it.
@export var copies: int = 1
## Scales a strong (vulnerable) hit's bonus: 1.0 is the plain table, 2.0 doubles the bonus.
@export var vulnerability_scale: float = 1.0
## A resisted hit counts as a neutral one.
@export var ignores_resistance: bool = false
## Buff scroll id to the number of stacks used, for display.
var buff_stacks: Dictionary = {}

var _attack_profile: AttackProfile


## The elements and flags a hit needs, built once. Call it after the spell is fully built, because
## it is cached.
func attack_profile() -> AttackProfile:
	if _attack_profile == null:
		_attack_profile = AttackProfile.new()
		for element in elements:
			_attack_profile.elements.append(element)
		_attack_profile.vulnerability_scale = vulnerability_scale
		_attack_profile.ignores_resistance = ignores_resistance
	return _attack_profile


func primary_element() -> int:
	return elements[0] if not elements.is_empty() else NO_ELEMENT


func area_type() -> AreaData.AreaType:
	return area_data.type


func effective_range() -> float:
	return maxf(area_data.default_range * range_scale, MIN_RANGE)


func effective_size() -> float:
	return maxf(area_data.default_size * size_scale, MIN_SIZE)


## Where a ground-targeted spell lands: the target, held within effective_range() of the origin.
func clamp_target(origin: Vector2, target: Vector2) -> Vector2:
	return origin + (target - origin).limit_length(effective_range())
