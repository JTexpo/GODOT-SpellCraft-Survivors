class_name ScrollData
extends Resource
## One kind of scroll. Category-specific data lives in the optional fields: `element` for Base,
## `area_data` for Area, `buff_id` for Buff (the buff's effect arrives in Sprint 7).

enum Category { BASE, AREA, BUFF }
enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category = Category.BASE
@export var rarity: Rarity = Rarity.COMMON
## Placeholder look until there is art.
@export var color: Color = Color.WHITE
## Base scrolls: the element the scroll adds. None (-1) for the other categories.
@export_enum("None:-1", "Fire:0", "Thunder:1", "Land:2", "Sea:3") var element: int = -1
## Area scrolls: the Area the scroll adds.
@export var area_data: AreaData
## Buff scrolls: which buff the scroll gives.
@export var buff_id: StringName
## Base scrolls: how this element changes an Area's baseline when crafted.
@export var modifiers: BaseModifiers
