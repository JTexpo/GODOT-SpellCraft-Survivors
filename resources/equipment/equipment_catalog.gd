class_name EquipmentCatalog
extends Resource
## Every item the shop sells. Adding an item is a new .tres plus an entry here.

const DEFAULT_PATH := "res://resources/equipment/equipment_catalog.tres"

@export var items: Array[EquipmentData] = []


static func default_catalog() -> EquipmentCatalog:
	return load(DEFAULT_PATH) as EquipmentCatalog


## Null if no item has that id.
func find(id: StringName) -> EquipmentData:
	for item in items:
		if item.id == id:
			return item
	return null


## The items that go in a slot, in catalog order.
func items_for_slot(slot: EquipmentData.Slot) -> Array[EquipmentData]:
	var found: Array[EquipmentData] = []
	for item in items:
		if item.slot() == slot:
			found.append(item)
	return found
