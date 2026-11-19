class_name SpellBar
extends Control
## TEMPORARY (Sprint 2): placeholder row of five spell slots. Reads the loadout and never
## changes it. A tap on a slot is forwarded as slot_pressed, and Main routes it to select().

signal slot_pressed(index: int)

const GAP := 2.0

var widgets: Array[SpellSlotWidget] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(loadout: SpellLoadout) -> void:
	for i in SpellLoadout.SLOT_COUNT:
		var widget := SpellSlotWidget.new()
		add_child(widget)
		widget.position = Vector2(i * (SpellSlotWidget.SIZE.x + GAP), 0.0)
		widget.pressed.connect(_on_widget_pressed)
		var instance := loadout.slots[i]
		widget.setup(i, instance.data if instance != null else null)
		if instance != null:
			widget.set_mana(instance.current_mana, instance.data.max_mana)
			instance.mana_changed.connect(widget.set_mana)
		widgets.append(widget)
	loadout.selection_changed.connect(_on_selection_changed)
	loadout.cast_failed_dry.connect(_on_cast_failed_dry)
	_on_selection_changed(loadout.selected_index)


func _on_widget_pressed(index: int) -> void:
	slot_pressed.emit(index)


func _on_selection_changed(index: int) -> void:
	for i in widgets.size():
		widgets[i].set_selected(i == index)


func _on_cast_failed_dry(index: int) -> void:
	widgets[index].flash_dry()
