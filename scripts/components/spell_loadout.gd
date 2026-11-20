class_name SpellLoadout
extends Node
## The player's five spell slots: which spell is selected, and casting it. Mana lives on each
## SpellInstance. A spell that runs dry stays selected and simply does nothing, so the player
## never wastes another spell by accident. Input handling stays with the Player.

signal selection_changed(index: int)
signal cast_fired(index: int)
## Emitted once per press when the selected spell has no mana left.
signal cast_failed_dry(index: int)
## A slot got a new spell (crafting). The slot holds a fresh SpellInstance.
signal slot_changed(index: int)
## A locked slot became available.
signal slot_unlocked(index: int)

const SLOT_COUNT := 5
## Stands in for "far away" when a cast has no target point.
const FAR_TARGET_DISTANCE := 10000.0

## Index = slot. A null entry is an empty slot.
@export var starting_spells: Array[SpellData] = []
## How many slots, counting from the first, the player can use. The rest are locked and hold
## nothing. Sprint 8's levels will raise this.
@export var unlocked_slots: int = SLOT_COUNT
## Where projectiles are added. Defaults to the owner's parent.
var projectile_root: Node

var slots: Array[SpellInstance] = []
var selected_index: int = 0
## The level's spell mana bonus, given to every spell here (see SpellInstance.max_mana_bonus).
var mana_bonus: float = 0.0
## Every bonus that reaches a cast (element and spell damage, casting speed, the two chance effects)
## and the mana bonus. Kept here so the crafting preview can show what a cast will really do.
var bonuses: StatBonuses = StatBonuses.new()
## Rolls the chance effects. Tests seed it.
var rng := RandomNumberGenerator.new()

var _dry_latched: bool = false


func _ready() -> void:
	rng.randomize()
	slots.clear()
	for i in SLOT_COUNT:
		var spell: SpellData = starting_spells[i] if i < starting_spells.size() and is_unlocked(i) else null
		slots.append(_new_instance(spell) if spell != null else null)


func _process(delta: float) -> void:
	for spell in slots:
		if spell != null:
			spell.tick(delta)


func selected() -> SpellInstance:
	return slots[selected_index] if selected_index < slots.size() else null


func is_unlocked(index: int) -> bool:
	return index >= 0 and index < mini(unlocked_slots, SLOT_COUNT)


## Unlocks the next locked slot. False if all of them are already unlocked.
func unlock_next() -> bool:
	if unlocked_slots >= SLOT_COUNT:
		return false
	unlocked_slots += 1
	slot_unlocked.emit(unlocked_slots - 1)
	return true


## Sets how many slots are usable (from 1 to SLOT_COUNT) and emits `slot_unlocked` for each slot that
## just opened, so the spell bar redraws them. Lowering it emits nothing.
func set_unlocked_slots(count: int) -> void:
	var before := unlocked_slots
	unlocked_slots = clampi(count, 1, SLOT_COUNT)
	for index in range(before, unlocked_slots):
		slot_unlocked.emit(index)


## Puts a new spell, with a full mana pool, in an unlocked slot, replacing whatever was there.
## Returns the new instance, or null (changing nothing) if the slot is locked or out of range.
func equip(index: int, spell: SpellData) -> SpellInstance:
	if spell == null or not is_unlocked(index) or index >= slots.size():
		return null
	var instance := _new_instance(spell)
	slots[index] = instance
	if index == selected_index:
		_dry_latched = false
	slot_changed.emit(index)
	return instance


## Sets every bonus at once: the mana bonus and casting speed on each spell now in a slot (and on any
## equipped later), and the damage and chance bonuses the next cast reads.
func set_bonuses(new_bonuses: StatBonuses) -> void:
	bonuses = new_bonuses
	set_mana_bonus(bonuses.fraction(StatBonuses.Stat.SPELL_MANA))
	for spell in slots:
		if spell != null:
			spell.set_cast_speed_bonus(bonuses.fraction(StatBonuses.Stat.CAST_SPEED))


## Sets the level's mana bonus on every spell now in a slot, and on every spell equipped later.
func set_mana_bonus(bonus: float) -> void:
	mana_bonus = bonus
	for spell in slots:
		if spell != null:
			spell.set_max_mana_bonus(bonus)


func select(index: int) -> bool:
	if not is_unlocked(index) or index >= slots.size() or index == selected_index or slots[index] == null:
		return false
	selected_index = index
	_dry_latched = false
	selection_changed.emit(index)
	return true


## Moves to the next filled slot in the direction of `step` (wrapping). False if there is none.
func cycle(step: int) -> bool:
	var direction := 1 if step >= 0 else -1
	for offset in range(1, SLOT_COUNT):
		var index := posmod(selected_index + direction * offset, SLOT_COUNT)
		if slots[index] != null:
			return select(index)
	return false


## `target` is where the player points (the mouse, or far along a stick). A non-finite target
## means "far along direction". Ground-targeted Areas clamp it to their own range.
func try_cast(origin: Vector2, direction: Vector2, target: Vector2 = Vector2.INF) -> bool:
	var spell := selected()
	if spell == null or direction == Vector2.ZERO:
		return false
	if not spell.has_mana():
		if not _dry_latched:
			_dry_latched = true
			cast_failed_dry.emit(selected_index)
		return false
	if spell.data.area_data == null or spell.data.area_data.scene == null:
		return false
	if not spell.cast():
		return false
	if not target.is_finite():
		target = origin + direction * FAR_TARGET_DISTANCE
	var root := projectile_root if projectile_root != null else get_parent().get_parent()
	var damage_scale := CastMath.damage_scale(spell.data.elements, bonuses)
	if _roll(CastMath.chance(bonuses, StatBonuses.Stat.DOUBLE_DAMAGE_CHANCE)):
		damage_scale *= 2.0
	var passes := 2 if _roll(CastMath.chance(bonuses, StatBonuses.Stat.CAST_TWICE_CHANCE)) else 1
	var shots := CastPattern.shots(spell.data, origin, direction, target)
	for _pass in passes:
		for shot in shots:
			var effect := spell.data.area_data.scene.instantiate() as AreaEffect
			effect.damage_scale = damage_scale
			root.add_child(effect)
			effect.launch(spell.data, origin, shot.direction, shot.target)
	cast_fired.emit(selected_index)
	return true


## Call when the player stops casting, so the next press can cue "dry" again.
func end_cast() -> void:
	_dry_latched = false


func _new_instance(spell: SpellData) -> SpellInstance:
	var instance := SpellInstance.new(spell)
	if mana_bonus != 0.0:
		instance.set_max_mana_bonus(mana_bonus)
	instance.set_cast_speed_bonus(bonuses.fraction(StatBonuses.Stat.CAST_SPEED))
	return instance


## True with the given chance (0 never, 1 always).
func _roll(chance: float) -> bool:
	return chance >= 1.0 or (chance > 0.0 and rng.randf() < chance)


func restore_all_mana() -> void:
	for spell in slots:
		if spell != null:
			spell.restore_mana()
