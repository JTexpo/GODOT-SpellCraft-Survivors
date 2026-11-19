# Sprint Development Plan

## Project Overview

This document outlines the incremental development plan for the wizard survival roguelite.

Development is divided into focused sprints, with each sprint introducing a specific set of mechanics or improvements.

The goal is to maintain a playable version of the game throughout development rather than attempting to implement every system simultaneously.

### Development Principles

- Each sprint should produce a playable build.
- Prioritize core gameplay before progression and additional content.
- Avoid introducing multiple interconnected systems in the same sprint unless necessary.
- Build systems to be expandable rather than hardcoding individual implementations.
- Test and balance mechanics before building additional systems on top of them.
- Keep development focused on the minimum viable game before expanding its content.

### Important Design Decisions

The following decisions should be treated as established design requirements:

- Spells have limited mana.
- Spells do not naturally regenerate mana.
- Once a spell's mana is depleted, it cannot be cast again unless its mana is explicitly restored.
- Players must move around the map to survive and manage their available resources.
- The visual style is colorful, comedic, cartoon-inspired pixel art.
- The game uses a top-down perspective.
- The game is inspired by the survival and progression mechanics of Vampire Survivors, while emphasizing player-created spells.

---

# Sprint 0: Project Foundation

**Goal:** Establish the project structure and technical foundation.

### Tasks

- [x] Create the game project.
- [x] Configure the target resolution.
- [x] Configure pixel-art rendering and filtering.
- [x] Establish the top-down camera.
- [x] Implement basic scene management.
- [x] Establish input handling for keyboard and mouse.
- [x] Establish input handling for controller/joystick.
- [x] Create a basic player placeholder.
- [x] Create a basic enemy placeholder.
- [x] Establish a reusable entity/component structure.
- [x] Establish a reusable data structure for spells.
- [x] Establish a reusable data structure for scrolls.
- [x] Establish version control and repository structure.

### Deliverable

A blank playable environment containing a controllable placeholder character.

### Completion Criteria

- The project runs without errors.
- The player can be controlled.
- The camera follows the player.
- The project can be built and tested consistently.

---

# Sprint 1: Player Movement and Combat Foundation

**Goal:** Establish the fundamental gameplay experience.

Before implementing spell crafting, the player needs to feel good to control.

### Tasks

#### Player

- [x] Implement player movement.
- [x] Implement movement speed.
- [x] Implement player health.
- [x] Implement player damage and death.
- [x] Implement enemy collision.
- [x] Implement player damage feedback.
- [x] Implement basic knockback.

#### Enemies

- [x] Create a basic enemy.
- [x] Implement enemy movement toward the player.
- [x] Implement enemy collision damage.
- [x] Implement enemy health.
- [x] Implement enemy death.
- [x] Implement enemy spawning.
- [x] Implement configurable enemy spawn rates.

#### Combat

- [x] Create a temporary basic attack.
- [x] Implement damage calculations.
- [x] Implement enemy damage feedback.
- [x] Implement basic combat effects.

### Deliverable

A playable environment where the player can move around, fight enemies, take damage, and die.

### Completion Criteria

- Player movement feels responsive.
- Enemies consistently pursue the player.
- Combat interactions work reliably.
- The player can survive against multiple enemies.
- Enemy spawning can be configured.

### Testing Focus

Spend time adjusting player movement speed, enemy speed, collision behavior, and enemy spawn rates.

These values will influence almost every other gameplay system.

---

# Sprint 2: Base Spell System

**Goal:** Implement the foundation of the spell system.

At this stage, spells are created directly through development tools or predefined configurations. Scroll collection and crafting will come later.

### Tasks

#### Spell Architecture

- [x] Create a reusable Spell data structure.
- [x] Implement spell Base types.
- [x] Implement spell damage.
- [x] Implement spell mana capacity.
- [x] Implement current spell mana.
- [x] Implement mana consumption.
- [x] Prevent casting when mana is depleted.
- [x] Implement spell casting intervals.
- [x] Implement spell cooldowns or casting delays where applicable.

#### Base Elements

- [x] Implement Fire.
- [x] Implement Thunder.
- [x] Implement Land.
- [x] Implement Sea.
- [x] Create configurable elemental damage modifiers.

#### Spell Casting

- [x] Implement basic spell casting.
- [x] Implement spell targeting.
- [x] Implement spell damage application.
- [x] Implement spell visual effects.
- [x] Implement spell impact feedback.

#### Mana

- [x] Implement individual spell mana pools.
- [x] Display spell mana in the UI.
- [x] Prevent spells from casting without sufficient mana.
- [x] Implement explicit mana restoration through test/debug tools.

**Important:** Mana does not naturally regenerate. Once depleted, a spell remains unusable until something explicitly restores its mana.

**Built note:** "spell targeting" is the aim direction, and "spell visual effects" is the element tint on the projectile. The elemental modifier table is built and tested, but it only takes effect once enemies have elements (Sprint 4).

### Deliverable

A player who can cast four different elemental spells, each with its own mana capacity and damage type.

### Completion Criteria

- Each elemental spell can be cast.
- Mana decreases when a spell is used.
- Spells stop working when mana reaches zero.
- Damage is correctly applied to enemies.
- Spells can have different damage and mana configurations.

---

# Sprint 3: Spell Areas and Behaviors

**Goal:** Expand spells beyond their elemental damage type.

This sprint introduces the Area system, allowing spells to behave differently depending on their configuration.

### Tasks

#### Line

- [x] Implement Line targeting.
- [x] Implement directional damage.
- [x] Implement configurable line length.
- [x] Implement configurable line width.

#### Cone

- [x] Implement Cone targeting.
- [x] Implement directional cone attacks.
- [x] Implement configurable cone angle.
- [x] Implement configurable cone range.

#### Area

- [x] Implement targeted Area attacks.
- [x] Implement mouse/joystick targeting.
- [x] Implement area-of-effect damage.
- [x] Implement configurable radius.
- [x] Implement configurable duration.

#### Missile

- [x] Implement projectile spawning.
- [x] Implement projectile direction.
- [x] Implement projectile movement.
- [x] Implement projectile collision.
- [x] Implement projectile lifetime.
- [x] Implement configurable projectile speed.
- [x] Implement configurable projectile range.

#### Wave (added in Sprint 3 at the user's request)

- [x] Implement a wide crescent that travels outward.
- [x] Hit every enemy it passes through once.
- [x] Implement configurable width, speed and range.

#### Spell Configuration

- [x] Allow Base and Area combinations.
- [x] Allow different mana costs for different Areas.
- [ ] Allow different damage values for different Areas.

### Deliverable

A functional spell system supporting all five Area types (Line, Cone, Area, Missile, Wave).

### Completion Criteria

- All five Areas behave as intended.
- Spells can use any Base type with any Area type.
- Area size and range are configurable.
- Mana consumption reflects the configured spell.
- Spells interact correctly with enemies.

**Built note:** every Area is its own scene behind one `launch` call, with defaults in an `AreaData` resource and a per-spell `range_scale` and `size_scale` for Sprint 6 crafting to set. The rule linking range to mana cost is left to the Spell Builder (Sprint 6). The starting loadout is Fire Missile, Thunder Cone, Land Area, Sea Line and Sea Wave. "Spells interact correctly with enemies" is true for damage and knockback. Elemental effects arrive in Sprint 4.

---

# Sprint 4: Elemental Affinities and Enemy Variety

**Goal:** Make elemental spell choices meaningful.

Enemies should have elemental strengths and weaknesses, encouraging players to experiment with different spell configurations.

### Tasks

#### Elemental Interactions

- [ ] Implement enemy elemental affinities.
- [ ] Implement elemental vulnerabilities.
- [ ] Implement elemental resistances.
- [ ] Implement neutral damage.
- [ ] Implement configurable vulnerability multipliers.
- [ ] Implement configurable resistance multipliers.

#### Enemy Variety

- [ ] Create a Fire enemy.
- [ ] Create a Thunder enemy.
- [ ] Create a Land enemy.
- [ ] Create a Sea enemy.
- [ ] Implement different enemy movement speeds.
- [ ] Implement different enemy health values.
- [ ] Implement different enemy damage values.

#### Visual Feedback

- [ ] Display damage numbers.
- [ ] Communicate vulnerability hits.
- [ ] Communicate resistance hits.
- [ ] Add elemental visual effects to enemies.

### Deliverable

A combat system where choosing the correct elemental spell provides a meaningful advantage.

### Completion Criteria

- Elemental interactions work correctly.
- Enemy affinities are configurable.
- Vulnerabilities and resistances are visually communicated.
- Players can identify which spells are effective against different enemies.

---

# Sprint 5: Spell Scroll Collection

**Goal:** Introduce the primary item collection mechanic.

Players can now discover spell-scrolls during an adventure.

### Tasks

#### Scroll Architecture

- [ ] Create a reusable Scroll data structure.
- [ ] Implement Base scrolls.
- [ ] Implement Area scrolls.
- [ ] Implement Buff scrolls.
- [ ] Assign scroll categories.
- [ ] Implement scroll pickup interactions.

#### Enemy Drops

- [ ] Implement enemy scroll drops.
- [ ] Implement configurable drop chances.
- [ ] Implement scroll drop tables.
- [ ] Implement scroll pickup visuals.
- [ ] Implement scroll collection feedback.

#### Inventory

- [ ] Create a scroll inventory.
- [ ] Display collected scrolls.
- [ ] Implement scroll stacking where appropriate.
- [ ] Display scroll categories.
- [ ] Implement inventory limits if required.

### Deliverable

Enemies can drop scrolls, and the player can collect and store them.

### Completion Criteria

- Scrolls drop from enemies.
- Scrolls can be collected.
- Scrolls are stored correctly.
- Different scroll categories are distinguishable.
- Collected scrolls persist for the duration of the run.

---

# Sprint 6: Arcane Lectern and Spell Crafting

**Goal:** Introduce the game's defining mechanic: player-created spells.

### Tasks

#### Lectern

- [ ] Create the Arcane Lectern entity.
- [ ] Implement Lectern interaction.
- [ ] Implement the crafting interface.
- [ ] Implement player proximity requirements.
- [ ] Implement crafting confirmation.

#### Spell Crafting

- [ ] Allow selection of a Base scroll.
- [ ] Allow selection of an Area scroll.
- [ ] Allow optional Buff scrolls.
- [ ] Validate spell combinations.
- [ ] Calculate resulting spell statistics.
- [ ] Calculate resulting mana requirements.
- [ ] Generate the resulting spell.
- [ ] Consume the appropriate scrolls.
- [ ] Allow crafted spells to replace existing spells.

#### Spell Management

- [ ] Display currently equipped spells.
- [ ] Allow spells to be equipped.
- [ ] Allow spells to be replaced.
- [ ] Respect the player's available spell slots.
- [ ] Display individual spell mana.

### Deliverable

Players can collect scrolls and craft their own spells using Arcane Lecterns.

### Completion Criteria

- Players can craft spells from collected scrolls.
- Crafting rules are enforced.
- Scrolls are consumed correctly.
- Crafted spells function in combat.
- Spell statistics update according to their components.

---

# Sprint 7: Buff System

**Goal:** Introduce additional spell customization.

Buffs allow players to create specialized spells with unique strengths and weaknesses.

### Tasks

#### Buff Implementation

- [ ] Implement Increased Max Mana.
- [ ] Implement Increased Damage.
- [ ] Implement Double Vulnerability Damage.
- [ ] Implement Ignore Resistance.
- [ ] Implement Duplicate Area.
- [ ] Implement Additional Base.

#### Buff Calculations

- [ ] Calculate combined spell damage.
- [ ] Calculate additional mana requirements.
- [ ] Calculate maximum mana.
- [ ] Calculate elemental interactions for multiple Base types.
- [ ] Calculate duplicated Area behavior.
- [ ] Validate buff combinations.

#### Crafting Interface

- [ ] Display available Buff scrolls.
- [ ] Display active Buffs.
- [ ] Preview resulting spell statistics.
- [ ] Display additional mana costs.
- [ ] Communicate potential drawbacks.

### Deliverable

A complete spell crafting system supporting Base, Area, and Buff combinations.

### Completion Criteria

- All Buffs function correctly.
- Buffs affect spell statistics.
- Mana requirements scale with Buffs.
- Multiple Buffs can be combined.
- The crafting interface communicates the resulting spell.

---

# Sprint 8: XP and Run Progression

**Goal:** Introduce progression during an adventure.

Players should become stronger as they survive and defeat enemies.

### Tasks

#### XP Collection

- [ ] Implement XP drops.
- [ ] Implement XP pickup.
- [ ] Implement XP accumulation.
- [ ] Implement XP display.
- [ ] Implement level-up thresholds.

#### Leveling System

- [ ] Implement the 20-level progression structure.
- [ ] Implement movement speed upgrades.
- [ ] Implement health upgrades.
- [ ] Implement maximum spell mana upgrades.
- [ ] Implement spell slot upgrades.
- [ ] Implement starting spell bonuses.
- [ ] Implement random Buff selection.
- [ ] Implement chosen Buff selection.
- [ ] Implement starting spell unlocks.

#### UI

- [ ] Display current XP.
- [ ] Display current level.
- [ ] Display XP progress toward the next level.
- [ ] Display level-up notifications.
- [ ] Display unlocked spell slots.

### Deliverable

A complete XP and leveling system that improves the player throughout an adventure.

### Completion Criteria

- XP is collected correctly.
- Level-ups trigger at the correct thresholds.
- All 20 progression rewards function.
- Spell slots unlock correctly.
- Starting spell modifications are applied correctly.

---

# Sprint 9: Gold and Permanent Progression

**Goal:** Introduce the between-run economy.

Players can now use Gold to purchase equipment that changes their future adventures.

### Tasks

#### Gold

- [ ] Implement Gold drops.
- [ ] Implement Gold collection.
- [ ] Implement Gold accumulation.
- [ ] Implement Gold persistence between runs.
- [ ] Display Gold collected during an adventure.

#### Equipment

- [ ] Implement Robes.
- [ ] Implement Wands.
- [ ] Implement Staffs.
- [ ] Implement Hats.
- [ ] Implement Hoods.
- [ ] Implement equipment modifiers.
- [ ] Implement equipment purchasing.
- [ ] Implement equipment selection.
- [ ] Implement equipment persistence.

#### Equipment Bonuses

- [ ] Implement elemental damage bonuses.
- [ ] Implement maximum mana bonuses.
- [ ] Implement health bonuses.
- [ ] Implement movement speed bonuses.
- [ ] Implement Wand casting speed bonuses.
- [ ] Implement Staff damage bonuses.
- [ ] Implement equipment-specific special effects.

#### Shop Interface

- [ ] Create the equipment shop.
- [ ] Display equipment descriptions.
- [ ] Display equipment prices.
- [ ] Display player Gold.
- [ ] Implement purchasing confirmation.
- [ ] Prevent purchases without sufficient Gold.

### Deliverable

A functional between-run shop and equipment progression system.

### Completion Criteria

- Gold persists between adventures.
- Equipment can be purchased.
- Equipment bonuses apply correctly.
- Equipment selections persist between runs.
- Different equipment creates meaningful gameplay differences.

---

# Sprint 10: Potions and Consumables

**Goal:** Introduce temporary items that provide additional strategic options.

### Tasks

- [ ] Create a reusable Potion data structure.
- [ ] Implement Health Potions.
- [ ] Implement Mana Potions.
- [ ] Implement Speed Potions.
- [ ] Implement Damage Potions.
- [ ] Implement Invulnerability Potions.
- [ ] Implement Luck Potions.
- [ ] Implement potion purchasing.
- [ ] Implement potion inventory.
- [ ] Implement potion usage.
- [ ] Implement potion duration.
- [ ] Implement potion cooldowns or usage restrictions.

### Deliverable

Players can purchase and use consumables during an adventure.

### Completion Criteria

- Potions apply their intended effects.
- Potions are consumed correctly.
- Temporary effects expire correctly.
- Mana Potions can restore depleted spell mana.
- Potion effects are communicated through the UI.

---

# Sprint 11: Enemy Variety and Boss Encounters

**Goal:** Introduce more challenging combat encounters.

### Tasks

#### Enemy Archetypes

- [ ] Implement Swarmers.
- [ ] Implement Chasers.
- [ ] Implement Ranged Enemies.
- [ ] Implement Tanks.
- [ ] Implement Exploders.
- [ ] Implement Support Enemies.
- [ ] Implement Elite Enemies.

#### Bosses

- [ ] Create a boss architecture.
- [ ] Implement boss health.
- [ ] Implement boss-specific attacks.
- [ ] Implement attack patterns.
- [ ] Implement multiple attack phases.
- [ ] Implement boss spawning.
- [ ] Implement boss rewards.
- [ ] Implement boss death and encounter completion.

#### Difficulty

- [ ] Implement enemy health scaling.
- [ ] Implement enemy damage scaling.
- [ ] Implement enemy spawn scaling.
- [ ] Implement elite enemy spawn rates.
- [ ] Implement timed encounters.
- [ ] Implement boss encounter intervals.

### Deliverable

A variety of enemies and at least one fully functional boss encounter.

### Completion Criteria

- Enemy archetypes behave differently.
- Boss encounters require active player movement.
- Difficulty increases over time.
- Boss rewards function correctly.

---

# Sprint 12: World Design and Exploration

**Goal:** Make the world more interesting to explore.

### Tasks

- [ ] Create the first playable map.
- [ ] Implement environmental boundaries.
- [ ] Implement environmental obstacles.
- [ ] Implement treasure chests.
- [ ] Implement Arcane Lectern placement.
- [ ] Implement Health Shrines.
- [ ] Implement Mana Shrines.
- [ ] Implement merchant encounters.
- [ ] Implement rare scroll locations.
- [ ] Implement environmental decorations.
- [ ] Implement map-specific enemy spawn configurations.

### Deliverable

A complete playable environment with points of interest that encourage exploration.

### Completion Criteria

- The player has reasons to explore.
- Points of interest are distributed throughout the map.
- Environmental obstacles interact correctly with movement and combat.
- The map supports the intended survival gameplay.

---

# Sprint 13: Art, Animation, Audio, and Polish

**Goal:** Establish the game's visual and audio identity.

The intended art direction is comedic, colorful, and cartoon-inspired pixel art.

The world should feel like a playful fantasy adventure rather than a grim-dark survival experience.

### Art Direction

- [ ] Establish a consistent pixel-art resolution.
- [ ] Establish a limited color palette.
- [ ] Create the player character sprite.
- [ ] Create player movement animations.
- [ ] Create player casting animations.
- [ ] Create enemy sprites.
- [ ] Create enemy movement animations.
- [ ] Create enemy attack animations.
- [ ] Create elemental spell sprites.
- [ ] Create scroll sprites.
- [ ] Create equipment sprites.
- [ ] Create Lectern sprites.
- [ ] Create environmental tiles.
- [ ] Create UI elements.

### Animation

- [ ] Player idle animation.
- [ ] Player movement animation.
- [ ] Player casting animation.
- [ ] Player damage animation.
- [ ] Enemy movement animations.
- [ ] Enemy attack animations.
- [ ] Enemy death animations.
- [ ] Spell projectile animations.
- [ ] Spell impact animations.
- [ ] Item pickup animations.

### Audio

- [ ] Implement background music.
- [ ] Implement player movement sounds where appropriate.
- [ ] Implement spell casting sounds.
- [ ] Implement spell impact sounds.
- [ ] Implement enemy sounds.
- [ ] Implement enemy death sounds.
- [ ] Implement item pickup sounds.
- [ ] Implement UI sounds.
- [ ] Implement boss encounter music.

### Polish

- [ ] Add screen shake where appropriate.
- [ ] Add particle effects.
- [ ] Add damage indicators.
- [ ] Add visual feedback for low mana.
- [ ] Add visual feedback for level-ups.
- [ ] Add visual feedback for rare item drops.

### Deliverable

A visually cohesive and audio-complete game with a recognizable cartoon fantasy identity.

### Completion Criteria

- Art assets share a consistent style.
- Animations communicate gameplay actions clearly.
- Important combat effects are readable.
- Audio feedback supports gameplay without becoming overwhelming.

---

# Sprint 14: Balancing and Optimization

**Goal:** Ensure the game is enjoyable, stable, and performant.

### Tasks

#### Gameplay Balancing

- [ ] Balance player health.
- [ ] Balance player movement speed.
- [ ] Balance enemy movement speed.
- [ ] Balance enemy health.
- [ ] Balance enemy damage.
- [ ] Balance enemy spawn rates.
- [ ] Balance spell damage.
- [ ] Balance spell mana consumption.
- [ ] Balance spell casting speed.
- [ ] Balance elemental multipliers.
- [ ] Balance Buff effectiveness.
- [ ] Balance equipment bonuses.
- [ ] Balance XP progression.
- [ ] Balance Gold rewards.
- [ ] Balance boss difficulty.

#### Testing

- [ ] Test all Base and Area combinations.
- [ ] Test all Buff combinations.
- [ ] Test multiple equipped spells.
- [ ] Test depleted mana scenarios.
- [ ] Test equipment combinations.
- [ ] Test potion interactions.
- [ ] Test level progression.
- [ ] Test player death.
- [ ] Test run completion.
- [ ] Test save/load functionality.

#### Optimization

- [ ] Optimize enemy spawning.
- [ ] Optimize projectile handling.
- [ ] Implement object pooling where beneficial.
- [ ] Optimize particle effects.
- [ ] Profile performance with large enemy counts (Sprint 1 desktop baseline: 60 fps target met at 300 and 500 enemies, see `development-log.md`; re-measure on phones/browsers).
- [ ] Add crowd separation if enemy stacking hurts readability (enemies currently converge on the player).
- [ ] Fix memory leaks.
- [ ] Fix known gameplay bugs.

### Deliverable

A balanced and stable version of the game that can support extended play sessions.

### Completion Criteria

- No critical gameplay bugs remain.
- Performance remains stable during large encounters.
- Progression is balanced.
- Spells have meaningful strengths and weaknesses.
- The game remains enjoyable throughout an entire run.

---

# Sprint 15: Release Preparation

**Goal:** Prepare the game for its first public release.

### Tasks

- [ ] Implement the main menu.
- [ ] Implement settings.
- [ ] Implement audio settings.
- [ ] Implement control settings.
- [ ] Implement pause menu.
- [ ] Implement game-over screen.
- [ ] Implement run statistics.
- [ ] Implement persistent save data.
- [ ] Implement tutorial/onboarding.
- [ ] Implement credits.
- [ ] Create game icon.
- [ ] Create promotional screenshots.
- [ ] Create promotional artwork.
- [ ] Perform final playtesting.
- [ ] Fix release-blocking bugs.
- [ ] Create release build.

### Deliverable

A complete, playable release candidate.

### Completion Criteria

- The player can start and finish an adventure.
- Progression persists between sessions.
- All major systems function correctly.
- The game has a complete user interface.
- The game is ready for external playtesting.

---

# Development Milestones

The sprints can be grouped into larger milestones to track overall progress.

| Milestone | Sprints | Result |
|---|---|---|
| Foundation | 0–1 | Playable character and basic combat |
| Spell Framework | 2–4 | Functional elemental spell system |
| Spell Crafting | 5–7 | Complete scroll collection and crafting |
| Progression | 8–10 | XP, Gold, equipment, and consumables |
| Content | 11–12 | Enemies, bosses, and world exploration |
| Polish | 13–14 | Art, audio, balancing, and optimization |
| Release | 15 | Release candidate |

# MVP: Minimum Viable Product

Before attempting to complete every sprint, establish a smaller playable version of the game.

The MVP should contain:

- One playable wizard.
- One playable map.
- Four elemental Base types.
- Four Area types.
- Basic Buff functionality.
- A limited selection of enemies.
- Enemy spawning.
- Scroll drops.
- Scroll collection.
- One Arcane Lectern.
- Spell crafting.
- Individual spell mana pools with no natural regeneration.
- XP collection.
- Basic leveling.
- Player health and death.
- A basic game-over screen.

The MVP does not need:

- Multiple biomes.
- Multiple bosses.
- Full equipment progression.
- Potions.
- Rare scrolls.
- Spell evolution.
- Multiple playable characters.
- Extensive enemy variety.

The purpose of the MVP is to validate the central gameplay loop.

**If collecting scrolls, crafting spells, and surviving with limited mana isn't fun in the MVP, additional content won't solve that problem.**

# Sprint Completion Checklist

Every sprint should end with the following checks:

- [ ] All planned tasks are completed or explicitly deferred.
- [ ] New features have been tested.
- [ ] Existing features still function.
- [ ] Known bugs have been documented.
- [ ] Gameplay has been tested in a playable build.
- [ ] Code and assets have been committed to version control.
- [ ] The next sprint's objectives have been reviewed.

# Final Development Philosophy

Build the game from the inside out.

First establish movement and combat, then introduce spell behavior, then spell crafting, and finally the progression systems that give players reasons to keep playing.

Avoid spending too much time on content before the underlying mechanics are proven to be enjoyable.

A small, polished game with an engaging spell-crafting loop is a much stronger foundation than a large game with many unfinished systems.