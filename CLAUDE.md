# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project State

ScrollSmith Survivors (formerly Wizard Survivor; repo: GODOT-SpellCraft-Survivors until it is renamed) is an 8-bit, top-down survival roguelite in the style of Vampire Survivors, built with **Godot 4.x and GDScript** (2D). Sprint 0 (foundation), Sprint 1 (movement and combat foundation), Sprint 2 (base spell system) and Sprint 3 (spell Areas), Sprint 4 (elemental enemies), Sprint 5 (scroll collection) and Sprint 6 (Lectern and crafting) are done. See `sprint-0-design.md`, `sprint-1-design.md`, `sprint-2-design.md`, `sprint-3-design.md`, `sprint-4-design.md`, `sprint-5-design.md`, `sprint-6-design.md` and `docs/superpowers/plans/`. Decisions and measurements are logged in `development-log.md`.

## Commands

Run everything with the venv active (`source venv/bin/activate`). Godot is the Homebrew `godot` (4.7.2). After adding or renaming a `class_name` script, run `godot --headless --import` once so the class cache updates.

- Run all tests (GUT 9.7.1, vendored in `addons/gut/`): `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- Run one test file: add `-gselect=test_health_component` (file name without `.gd`)
- Run one test: add `-gunit_test_name=test_name`
- Smoke-run the project: `godot --headless --quit-after 60`
- Run the game: `godot --path .` (or open `project.godot` in the editor and press F5)
- Stress test (windowed): `godot --path . res://scenes/world/stress_test.tscn -- --enemies=300 --seconds=10` prints one `STRESS` line with fps and frame times. Target is 60 fps at 300 enemies.

The `godot` MCP server (`@coding-solo/godot-mcp`, launched via `npx`) is configured in `.mcp.json`. Node and `npx` live only in the gitignored `venv/` (installed with `nodeenv`), so start Claude Code from a shell where you ran `source venv/bin/activate`, or the server fails to connect. Godot itself (4.7.2) comes from Homebrew.

Established in Sprint 0: 480×270 internal resolution with integer scaling, Compatibility renderer, a checked-in single-threaded Web export preset, published to GitHub Pages by `.github/workflows/deploy-web.yml` (see Web build below), GUT for tests (`tests/test_*.gd`), and a `TouchJoystick` for touch movement (Godot 4.7 has a native `VirtualJoystick`, so don't reuse that name).

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

## Scrolls (Sprint 5)

- `ScrollData` is one class with a category (BASE, AREA, BUFF), a rarity, a placeholder colour, and optional category fields: `element` (Base), `area_data` (Area, the Sprint 3 `AreaData`), `buff_id` (Buff, its effect arrives in Sprint 7). The 15 scrolls live in `resources/scrolls/{base,area,buff}/`. Adding a scroll is a new `.tres` plus a drop-table entry, with no code change. The inventory, drop tables and crafting only ever hold `ScrollData`.
- Drops: `EnemyData.drop_table` (a `DropTable` of `DropEntry` scroll and weight pairs, plus `drop_chance`). `DropTable.roll(rng)` never picks null, scroll-less or zero-weight entries. Tables are themed: an elemental enemy weights its own element's Base scroll 12 and the other Bases 1, so it is heavily preferred but never guaranteed. Enemies carry data only. `EnemySpawner.enemy_died` is re-emitted, `Main` routes it to `ScrollDropper`, which rolls the table and places a pickup. The cap is 100 pickups, and a new drop removes the oldest.
- Pickups: `ScrollPickup` is a passive `Area2D` on layer 6 (`PhysicsLayers.PICKUP`), shaped by category (round Base, square Area, diamond Buff). One `PickupCollector` on the Player is the only active detector. Collection is automatic, a pickup can only be collected once, and a dead player collects nothing.
- `ScrollInventory` is a component on the Player (per run, stacks by scroll id, no limit): `add`, `remove` (all or nothing), `count`, `has`, `by_category`, `total_count`, and a `changed` signal. Crafting (Sprint 6) reads and consumes it through those methods.
- `ScrollToast`, `InventoryPanel` (key `I`, controller button Y) and `InventoryButton` are TEMPORARY HUD. The panel does not pause the game. F10 (`debug_give_scrolls`, handled in `Main`, DEBUG) gives 3 of every scroll.

## Crafting (Sprint 6)

- The player starts with one spell (Fire Missile, a 1000-cast pool) and four locked slots. `SpellLoadout.unlocked_slots` (5 by default, 1 on the player) says how many slots can be used. `equip(index, spell_data)` puts a fresh full-mana `SpellInstance` in an unlocked slot and emits `slot_changed`. `unlock_next()` unlocks one more slot and emits `slot_unlocked` (Sprint 8's levels will call it, and F11 does for testing). `select` and `cycle` skip locked slots, and the `SpellBar` dims them and follows a slot when its spell is replaced.
- **All crafting rules live in two static classes.** `SpellBuilder.build(base, area, option)` makes a `SpellData`: damage, interval, speed and knockback are the Area's baseline (`AreaData.base_stats`, an `AreaStats`) times the Base scroll's multiplier (`ScrollData.modifiers`, a `BaseModifiers`). Mana cost is also times the range option's cost multiplier, and the mana pool is not, so a longer range gives fewer casts. `CraftingSystem.validate/craft/preview` check a `CraftingRequest`, consume exactly one Base and one Area scroll all-or-nothing (a failed craft never touches the inventory or loadout), and equip the spell. Fire plus Missile at Normal range equals `fire_missile.tres` in every number except the pool: the starting spell has a generous 1000, while a crafted spell uses the Area baseline of 100. Range options (Short, Normal, Long, Very long) are in `resources/crafting/crafting_rules.tres`. Nothing is hand-written per Base and Area pair.
- Buff scrolls show in the crafting screen but are locked until Sprint 7 (a request with buffs is invalid). Size is not chosen at crafting, only range.
- `CraftingSession` (no UI) holds the screen's choices and previews. `CraftingScreen` (TEMPORARY look) is a thin layer over it and holds no rules. It works with mouse, keyboard or controller focus, and touch through `TouchBridge`, because `emulate_mouse_from_touch` is off. The bridged click goes straight into the viewport with `push_input` (not `Input.parse_input_event`, which would scale the position twice and press the global `cast` action).
- **Pause.** Opening the screen pauses the scene tree (`CraftingScreen` has `process_mode = Always`) through `GamePause.set_paused`, which also freezes `GameTime`, a clock that stands still while paused. `HitboxComponent.try_hit` reads `GameTime.now_msec()`, so hit cooldowns survive a pause. `Main` resets `GameTime` on load. After the screen closes, `Player.require_cast_release()` keeps the player from casting until the cast input is released once (it reads the real input, because `aim.is_firing` is stale on the first frame after a pause).
- **Lecterns** are passive `Area2D`s on layer 7 (`PhysicsLayers.INTERACTABLE`) in the group `lecterns`. They hold no crafting logic and only emit `interacted`. The Player's `InteractionComponent` tracks the nearest one in range, shows its prompt, and `interact` (E, controller A) or the touch `InteractButton` uses it. A dead player cannot interact. Three Lecterns are placed in `main.tscn`, off-screen from the start. They are reusable, unlimited and free.
- F10 (`debug_give_scrolls`), F11 (`debug_unlock_slot`) and F9 (`debug_restore_mana`) are DEBUG keys handled in `Main`, to delete when their real systems exist.

## Web build and GitHub Pages

- `.github/workflows/deploy-web.yml` builds the `Web` export preset with Godot 4.7.2 and publishes it with GitHub Pages. It runs when `main` changes and from the Actions tab ("Run workflow"). It downloads the Godot editor and the export templates for the version pinned in the workflow's `GODOT_RELEASE`, checks them against Godot's published SHA-512 sums, and caches the editor and the two web templates it needs. **When the project moves to a new Godot version, change `GODOT_VERSION` and `GODOT_RELEASE` there.**
- One-time setup (a repository setting, not code): Settings > Pages > Build and deployment > Source: **GitHub Actions**. The game is then at `https://jtexpo.github.io/GODOT-SpellCraft-Survivors/` (the last part changes if the repository is renamed).
- The preset is single-threaded (`variant/thread_support=false`, no extensions), because GitHub Pages cannot send the cross-origin isolation headers a threaded web build needs. PWA mode is off on purpose, so a phone never serves a stale cached build while testing. `exclude_filter` keeps GUT, the tests, the docs, `.github`, `venv` and `export` out of the package.
- Web builds need the `gl_compatibility` renderer, which the project already uses. The exported package is small (about 225 KB) and the engine file (`index.wasm`) is about 39 MB uncompressed.
- The `export/` folder is gitignored. To check an export on a machine **without installing templates into Godot's own folder**, make a throwaway copy of the project (for example with `rsync`, leaving out `.git`, `venv`, `.godot` and `export`), unpack only `templates/web_nothreads_release.zip` and `web_nothreads_debug.zip` from the `.tpz` into a scratch folder, and in the copy's `export_presets.cfg` set `custom_template/release` and `custom_template/debug` to those zip paths. Then run `godot --headless --path <copy> --import` and `godot --headless --path <copy> --export-release "Web" <copy>/export/web/index.html`, and serve that folder with `python -m http.server` on 127.0.0.1. Delete the copy afterwards.
- The F9, F10 and F11 debug keys are keyboard-only, so a phone has no way to give itself scrolls or unlock slots. Touch testing means playing for drops.

## Touch and input gotchas

- A `ColorRect` (like any `Control`) stops mouse and touch input by default (`mouse_filter` STOP), and a visible one swallows the event before `_unhandled_input` sees it. World decorations (the arena floor, the player and enemy bodies, Lectern parts, projectile bodies) must set `mouse_filter = 2` (IGNORE). `tests/test_world_input.gd` fails if a world scene gets a Control that stops touches. A phone's "tap to restart" was broken for exactly this reason: the arena floor covered the whole screen.
- Anything that must react to a tap anywhere (the death screen) listens in `_input`, which runs before any control, not in `_unhandled_input`. Widgets that handle their own touches (`SpellSlotWidget`, the Inventory and Interact buttons, `TouchJoystick`) already do.
- In headless GUT runs pointer events (mouse and touch) reach `_input` but never `_unhandled_input`, while keys reach both. So a headless test cannot show a swallowed tap. Check touch behaviour with a throwaway real-window script that sends `Input.parse_input_event` touches in window coordinates (multiply the game position by `root.get_final_transform()`), as was done for the touch bridge and for this bug.
