# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project State

Wizard Survivor (repo: SpellCraft Survivors) is an 8-bit, top-down survival roguelite in the style of Vampire Survivors, built with **Godot 4.x and GDScript** (2D). Sprint 0 (project foundation) is in progress on the `sprint-0-foundation` branch. See `sprint-0-design.md` and `docs/superpowers/plans/`. Decisions are logged in `development-log.md`.

## Commands

Run everything with the venv active (`source venv/bin/activate`). Godot is the Homebrew `godot` (4.7.2). After adding or renaming a `class_name` script, run `godot --headless --import` once so the class cache updates.

- Run all tests (GUT 9.7.1, vendored in `addons/gut/`): `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- Run one test file: add `-gselect=test_health_component` (file name without `.gd`)
- Run one test: add `-gunit_test_name=test_name`
- Smoke-run the project: `godot --headless --quit-after 60`

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
