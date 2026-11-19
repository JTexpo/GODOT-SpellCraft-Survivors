# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project State

Wizard Survivor (repo: SpellCraft Survivors) is an 8-bit, top-down survival roguelite in the style of Vampire Survivors, built with **Godot 4.x and GDScript** (2D). Sprint 0 (foundation), Sprint 1 (movement and combat foundation), Sprint 2 (base spell system) and Sprint 3 (spell Areas) and Sprint 4 (elemental enemies) are done. See `sprint-0-design.md`, `sprint-1-design.md`, `sprint-2-design.md`, `sprint-3-design.md`, `sprint-4-design.md` and `docs/superpowers/plans/`. Decisions and measurements are logged in `development-log.md`.

## Commands

Run everything with the venv active (`source venv/bin/activate`). Godot is the Homebrew `godot` (4.7.2). After adding or renaming a `class_name` script, run `godot --headless --import` once so the class cache updates.

- Run all tests (GUT 9.7.1, vendored in `addons/gut/`): `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- Run one test file: add `-gselect=test_health_component` (file name without `.gd`)
- Run one test: add `-gunit_test_name=test_name`
- Smoke-run the project: `godot --headless --quit-after 60`
- Run the game: `godot --path .` (or open `project.godot` in the editor and press F5)
- Stress test (windowed): `godot --path . res://scenes/world/stress_test.tscn -- --enemies=300 --seconds=10` prints one `STRESS` line with fps and frame times. Target is 60 fps at 300 enemies.

The `godot` MCP server (`@coding-solo/godot-mcp`, launched via `npx`) is configured in `.mcp.json`. Node and `npx` live only in the gitignored `venv/` (installed with `nodeenv`), so start Claude Code from a shell where you ran `source venv/bin/activate`, or the server fails to connect. Godot itself (4.7.2) comes from Homebrew.

Established in Sprint 0: 480×270 internal resolution with integer scaling, Compatibility renderer, a checked-in single-threaded Web export preset (not yet exported; templates aren't installed) for an eventual GitHub Pages release, GUT for tests (`tests/test_*.gd`), and a `TouchJoystick` for touch movement (Godot 4.7 has a native `VirtualJoystick`, so don't reuse that name).

## Required Workflow

The design docs are the source of truth. Read them before changing anything:

- `README.md`: game design document (GDD). Mechanics, progression tables, enemy and equipment design.
- `technical-design.md`: architecture, proposed directory layout, coding standards.
- `sprint-development.md`: Sprints 0–15 plus the MVP definition. Find the current sprint here.
- `claude-prompt.txt`: the user's per-task prompt template.

Per `claude-prompt.txt`, for every task:

1. Inspect the project, then propose the plan before writing code. List files to create or modify, dependencies, and architectural risks. **Wait for approval.**
2. Implement only the requested task. Follow existing conventions and avoid unrelated refactoring.
3. **Don't build features from future sprints.** Each sprint must leave a playable build.
4. Test the work. List the files changed and give manual test steps to run in Godot.
5. **Don't change game design decisions without asking.** Ask before changes that affect established mechanics.

## Architecture (big picture)

The core idea is that spells are **assembled at runtime from data**, never hardcoded per combination. A spell is a **Base** (one or more elements: Fire/Thunder/Land/Sea), exactly one **Area** (Line/Cone/Area/Missile), and optional **Buffs**.

Layering, per `technical-design.md`:

- **Scenes** are physical objects and UI (Player, Enemy, Projectile, Lectern, HUD, crafting menu).
- **Scripts** hold logic and systems.
- **Custom `Resource`s** hold all data definitions: `SpellData`, scroll, `EnemyData`, equipment and potion definitions.
- **Autoloads** are only for truly global or persistent state (Game/Run/Save managers). Avoid adding more.

Systems that must stay separate and reusable:

- **Spell Definition vs. Spell Instance.** `SpellData` is static configuration. A spell instance is the equipped runtime object with its own mana pool. Two instances of the same definition must never share mana.
- **Spell Builder.** It computes final damage, max mana, mana cost, cast interval, area dimensions, and buff effects. It must be independent of the crafting UI and the Lectern scene.
- **Crafting System.** It validates a combination, consumes scrolls, and creates or equips the spell. Invalid combinations must not consume scrolls. The Lectern is only the interaction point.
- **Damage System.** Elemental math is centralized in one place. Spells and enemies must not compute their own. Multipliers are configurable, not hardcoded. The rules for combining multiple Base types are undecided, so settle them before implementing Additional Base.
- **Area behaviors.** Each Area is an interchangeable implementation behind one casting interface. Modifiers like Duplicate Area must not require editing individual Areas.
- **Progression.** Run progression (XP, levels, slot unlocks) is separate from permanent progression (Gold, equipment, saves).
- **Equipment.** Effects go through one central modifier system, not direct edits to player stats. Hats and Hoods differ only visually.
- **Player, UI, and inventory.** The Player delegates to systems and holds no spell, enemy, or crafting logic. UI reads from systems and never mutates gameplay data directly. The scroll inventory is independent of the crafting UI.

## Established Design Rules (do not change without asking)

- **Mana never regenerates naturally.** Each spell has its own pool. A depleted spell can't be cast until something explicitly restores mana (potions, debug tools, or future effects). Spells must not cast with insufficient mana.
- Crafting needs at least one Base and exactly one Area. Buffs are optional. Every buff and every increase in range or area raises mana cost. Hybrid (multi-Base) spells drain mana faster.
- Elements: Fire > Land > Thunder > Sea > Fire. Each element is strong against the one it beats and weak against the one that beats it. Enemies without an affinity take normal damage.
- XP feeds a permanent 20-level wizard track (reward table in the README). Gold buys equipment between runs. Spell slots go from 1 to 5.
- Inputs go through the Godot Input Map using logical actions. Keyboard, mouse, and controller share one gameplay implementation (WASD, E interact, 1–5 spell slots, mouse aim, LMB cast, Esc pause).

## Conventions

- Naming: PascalCase classes. snake_case variables, functions, and signals. UPPER_SNAKE_CASE constants.
- Use typed GDScript where practical. One responsibility per script. Prefer composition over inheritance. Avoid circular dependencies. Use signals between independent systems.
- Gameplay and balance values belong in Resources or `@export` properties, not scattered through scripts.
- Directories from the proposed layout (`scenes/`, `scripts/{autoload,systems,utilities}/`, `resources/`, `assets/`, `tests/`) are created only as their systems are built.
- Don't optimize prematurely. Profile first. Object pooling for projectiles is the likely first optimization.
- Record significant architectural decisions. The layout in `technical-design.md` mentions a `development-log.md`, which doesn't exist yet.

## Combat architecture (Sprint 1)

- Combat is built from small components on an entity: `HealthComponent`, `HurtboxComponent` (receives hits, optional player-wide invulnerability window), `HitboxComponent` (deals damage, per-target cooldown, optional one-shot), `KnockbackComponent`, `HitFlashComponent`. All damage goes through `DamageSystem.calculate`, the single place elemental rules will live.
- Collision layers (named in `project.godot`, bit constants in `PhysicsLayers`): world, player_hurtbox, enemy_hurtbox, enemy_hitbox, player_projectile. Enemy hurtboxes and hitboxes are passive (`monitoring = false`), so only the player's hurtbox and projectiles do any overlap work. Enemies never detect each other.
- Enemies are light `Node2D`s moved by position (no `move_and_slide()`), clamped to the arena bounds. Stats come from `EnemyData` and spawning from `SpawnConfig`. The health bar and spell bar are marked TEMPORARY and expected to change in later sprints.
- Aim and fire go through `AimComponent` (mouse, right stick, or the touch aim stick) and `cast`. The Player forwards both to `SpellLoadout`. `emulate_mouse_from_touch` is off on purpose, so touching the move stick never fires.
- Hand-written `.tscn` files need `node_paths=PackedStringArray("prop")` on the `[node]` line for any exported Node-typed property set with a NodePath, or it stays null silently.
- `TouchJoystick` is ours. Godot 4.7 has a native `VirtualJoystick`, so don't reuse that name.

## Spell architecture (Sprint 2)

- `SpellData` (Resource) is static configuration: elements, damage, mana, cast interval, projectile stats, `max_hits`. `SpellInstance` (`RefCounted`) is the equipped runtime object and owns current mana and the cooldown. Never put mutable state on `SpellData`, because resources are shared and two copies of a spell must never share mana.
- `SpellLoadout` (component on the Player) holds five slots and the selected index, selects and cycles, and casts through `try_cast`. A depleted spell stays selected and does nothing (no auto-switch). Slot keys, controller shoulder buttons (`spell_prev`/`spell_next`) and the touch `SpellBar` all end in `select` or `cycle`. `try_cast` instantiates the spell's Area scene (see Sprint 3 below).
- `MissileArea` takes everything from the `SpellData` it is launched with. `HitboxComponent.max_hits` and `SpellData.max_hits` make piercing a data change.
- Elemental math lives only in `ElementTable` (configurable multipliers, Fire > Land > Thunder > Sea > Fire) and `DamageSystem.calculate(base, attacker_element, defender_element, table)`. Since Sprint 4 the multiplier is applied at impact (see Elemental enemies below).
- `SpellBar` and `SpellSlotWidget` are TEMPORARY HUD. Slot widgets read the loadout and handle touch taps themselves (`emulate_mouse_from_touch` is off) and ignore mouse clicks. F9 (`debug_restore_mana`, handled in `Main`) refills mana for testing.

## Area architecture (Sprint 3)

- Five Areas: Line, Cone, Area (ground zone), Missile, Wave. Each is its own scene under `scenes/spells/areas/`, whose root script extends `AreaEffect` and implements `launch(spell, origin, direction, target)`. `SpellLoadout.try_cast` instantiates `spell.area_data.scene` and calls it. Never branch on the Area type in the loadout, player or damage code.
- `AreaData` (Resource, `resources/spells/areas/`) holds one Area type's scene and defaults: `default_range`, `default_size`, `duration`, `tick_interval`, `widen_rate`, `needs_ground_target`. A `SpellData` points at one and carries `range_scale` and `size_scale`. `effective_range()` and `effective_size()` are the numbers every Area reads, and Sprint 6 crafting only has to write the two scales. Mana cost stays an authored number per spell. The rule "longer range costs more" belongs to the Spell Builder (Sprint 6), not the Areas.
- Ground-targeted Areas land at `SpellData.clamp_target(origin, target)`. The mouse's target is the cursor and a stick's is a far point along the aim, so a stick lands at full range. Targeting and the `TargetReticle` read `AreaData.needs_ground_target`.
- All Areas build their hit damage through `AreaEffect._configure_hitbox`, so Sprint 4 moves the elemental multiplier to hit time in one place. Line, Cone and Wave hit each enemy once per cast and Area hits once per tick, through `HitboxComponent.hit_cooldown`.
- Enemies are clamped to the arena bounds (no negative coordinates), so Area tests cast from an offset origin.

## Elemental enemies (Sprint 4)

- The elemental multiplier is applied when a hit lands. `HitboxComponent.element` is the attacker's element (set from the spell in `AreaEffect._configure_hitbox`, which carries raw damage) and `HurtboxComponent.element` is the defender's. `HurtboxComponent.receive_hit(damage, source_position, knockback, attacker_element)` gets the final damage from `DamageSystem.calculate` and an `ElementTable.Effect` (NEUTRAL, VULNERABLE, RESISTED) from `DamageSystem.effect`, then emits `hit_received(damage, source_position, knockback, effect)`. No other code does elemental math.
- Rules: an enemy has one element. It takes the strong multiplier from the element that beats it and the weak one from the element it beats. Same element, no element, or an unknown value is normal damage.
- The player's hurtbox has no element by default and enemy contact hitboxes carry none, so hits on the player are neutral. This is today's default, not a rule: equipment (robes, hats) may later give the player an element through `HurtboxComponent.element`, so never hardcode "the player is neutral".
- `EnemyData` has `element` (-1 for none), `color` and `spawn_weight`. There is one enemy scene. The five enemies (plain, Fire, Thunder, Land, Sea) differ only in data. `SpawnConfig.enemy_pool` lists them and `EnemySpawner.pick_enemy_data()` picks by weight.
- `Enemy.damaged(position, amount, effect)` is re-emitted by `EnemySpawner.enemy_damaged`, and `Main` routes it to `DamageNumbers` (TEMPORARY look), a pooled node that draws every number in one `_draw`. Vulnerable hits show larger, yellow and "!", resisted hits smaller and grey.
