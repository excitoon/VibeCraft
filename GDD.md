# VibeCraft — Game Design Document

> **Version:** 1.0  
> **Genre:** Real-Time Strategy / RPG Hybrid  
> **Platform:** PC (Windows, macOS, Linux)  
> **Engine:** Custom Elixir/OTP + OpenGL 3.3  
> **Target Rating:** E10+ (Everyone 10 and up)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Vision & Design Pillars](#vision--design-pillars)
3. [Core Gameplay Loop](#core-gameplay-loop)
4. [Factions](#factions)
5. [Units](#units)
6. [Buildings & Economy](#buildings--economy)
7. [Heroes & RPG Progression](#heroes--rpg-progression)
8. [Spells & Abilities](#spells--abilities)
9. [Inventory, Loot & Crafting](#inventory-loot--crafting)
10. [Map, Terrain & Environment](#map-terrain--environment)
11. [Fog of War](#fog-of-war)
12. [Campaign & Missions](#campaign--missions)
13. [Multiplayer](#multiplayer)
14. [AI Opponents](#ai-opponents)
15. [Replay System](#replay-system)
16. [Audio & Visual Style](#audio--visual-style)
17. [Technical Architecture](#technical-architecture)
18. [Development Roadmap](#development-roadmap)

---

## Executive Summary

**VibeCraft** is an original real-time strategy game with deep RPG elements.  Two
asymmetric factions — the **Human Alliance** and the **Orc Horde** — clash across
hand-crafted and procedurally supported battlefields spanning ground, sea, and air.

Players gather resources, construct bases, train armies, level up hero units, cast
powerful spells, and craft legendary items — all in real time.  A full single-player
campaign, ranked multiplayer ladder, custom map editor, and match replay system round
out the experience.

**Key differentiators:**

- Built on Elixir/OTP: the same technology that powers fault-tolerant telecoms now
  drives a concurrent, hot-reloadable game engine.
- 100 % original IP — every sprite, sound, and line of lore is ours.
- Deep mechanical layers spanning ground, naval, and air combat let new players
  ramp up while veterans dive into the full RPG/strategy sandbox.
- First-class multiplayer: deterministic tick-based simulation, TCP networking,
  Elo-rated matchmaking, and built-in replay recording.

---

## Vision & Design Pillars

### Vision Statement

*Deliver the definitive RTS/RPG hybrid experience using modern concurrency-first
technology and original art, proving that a small team on the BEAM can ship a
polished, competitive strategy title.*

### Design Pillars

| Pillar | Description |
|--------|-------------|
| **Accessible Depth** | Simple to learn (gather → build → fight), hard to master (hero builds, spell timing, map control) |
| **Dual-Faction Asymmetry** | Humans and Orcs share a resource model but diverge in unit stats, hero abilities, and strategic identity |
| **RPG Progression** | Heroes gain XP, level up, learn spells, equip items, and carry progress across campaign missions |
| **Fair Competition** | Deterministic simulation, server-authoritative networking, and Elo matchmaking ensure every match is decided by skill |
| **Moddability** | The Elixir macro-based scenario DSL and the built-in map editor empower the community to create content |

---

## Core Gameplay Loop

```
Gather ──► Build ──► Train ──► Scout ──► Fight ──► Expand
  ▲                                                   │
  └───────────────────────────────────────────────────┘
```

1. **Gather** — Workers harvest Gold from mines and Lumber from forests.
2. **Build** — Spend resources to construct production buildings.
3. **Train** — Queue military units and hero characters.
4. **Scout** — Push the fog of war back with expendable units.
5. **Fight** — Engage the enemy with combined-arms tactics across ground, naval,
   and air layers.
6. **Expand** — Secure additional resource nodes and repeat.

The loop runs on a **tick-based simulation** where every game tick advances
movement, combat, training queues, mana regeneration, and the day/night cycle
simultaneously.

**Victory condition:** Eliminate all enemy units and buildings.

---

## Factions

### Human Alliance

The Human Alliance relies on disciplined soldiers and industrious peasants.
Workers gather resources and construct buildings; fighters hold the line in
melee combat.  Their hero, the **Paladin**, excels at keeping the army alive
with powerful healing magic.

**Strengths:** Sustain, healing, balanced unit stats.  
**Weaknesses:** Lower raw damage output compared to the Horde.

### Orc Horde

The Orc Horde fields savage grunts backed by hard-working peons.  Grunt attacks
deal more damage than their Human counterparts, giving the Horde an aggressive
edge.  Their hero, the **Death Knight**, channels dark magic to destroy and
reanimate fallen foes.

**Strengths:** High burst damage, strong air power (Dragons).  
**Weaknesses:** Less healing, relies on aggressive tempo.

---

## Units

All units occupy a single tile and move one tile per tick in a cardinal direction
(north, south, east, west).  Units belong to one of three layers — **ground**,
**naval**, or **air** — each with its own movement rules.

### Ground Units

| Type       | Race  | Role    | HP | Attack | Sight | Gold | Lumber | Train (ticks) |
|------------|-------|---------|----|--------|-------|------|--------|---------------|
| Peasant    | Human | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| Footman    | Human | Fighter | 60 | 6      | 4     | 135  | 0      | 60            |
| Peon       | Orc   | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| Grunt      | Orc   | Fighter | 60 | 8      | 4     | 100  | 0      | 60            |

### Naval Units

Naval units move on water tiles and cannot traverse land.

| Type       | Role            | HP  | Attack | Sight |
|------------|-----------------|-----|--------|-------|
| Destroyer  | Naval fighter   | 100 | 10     | 5     |
| Battleship | Heavy naval gun | 150 | 15     | 6     |
| Oil Tanker | Naval worker    | 60  | 0      | 4     |
| Transport  | Troop carrier   | 80  | 0      | 4     |

### Air Units

Air units fly over any terrain and ignore ground/naval obstacles.

| Type    | Race  | Role        | HP  | Attack | Sight |
|---------|-------|-------------|-----|--------|-------|
| Gryphon | Human | Air fighter | 80  | 12     | 6     |
| Dragon  | Orc   | Air fighter | 120 | 16     | 6     |

### Worker Abilities

Workers (Peasant, Peon) can harvest resources.  Each trip to a mine or lumber
stand yields **10 Gold** or **10 Lumber**, deposited back at the nearest town
hall.  Workers can also construct buildings (planned).

---

## Buildings & Economy

### Buildings

Buildings occupy a single tile and maintain a first-in-first-out training queue
of up to **5** entries.  Only the front entry counts down each tick; finished
units spawn on an adjacent free tile.

| Type      | Race | HP   | Trains          |
|-----------|------|------|-----------------|
| Town Hall | Both | 1200 | Peasant / Peon  |
| Barracks  | Both | 800  | Footman / Grunt |

### Resources

Both factions share the same resource economy.

| Resource | Starting Amount | Gathered By     |
|----------|-----------------|-----------------|
| Gold     | 500             | Workers (mines) |
| Lumber   | 200             | Workers (trees) |

Resource management is the backbone of every strategic decision.  Gold funds
military units and hero items, while Lumber is required for advanced structures.
Controlling map resources — especially contested gold mines — is the key to
mid-game dominance.

---

## Heroes & RPG Progression

Heroes are powerful named characters that persist across campaign missions.
Each faction has one hero archetype.

| Hero         | Race  | Role             | HP  | Attack | Mana | Sight |
|--------------|-------|------------------|-----|--------|------|-------|
| Paladin      | Human | Holy warrior     | 150 | 12     | 200  | 5     |
| Death Knight | Orc   | Dark spellcaster | 150 | 15     | 200  | 5     |

### Experience & Leveling

- Heroes earn **XP** by defeating enemy units.
- XP thresholds increase with each level; the maximum level is **9**.
- Each level grants: **+50 HP**, **+2 Attack**, **+25 Max Mana**.
- A max-level Paladin has **600 HP**, **30 Attack**, **425 Max Mana**.

### Mana

- Mana is a separate resource pool consumed by spells.
- Mana regenerates passively over time.
- Managing mana between heals, damage, and utility spells is a core skill
  differentiator for experienced players.

---

## Spells & Abilities

Heroes learn spells as they level up.  Each spell costs mana and has an
immediate effect.

| Spell        | Hero         | Mana | Effect                       |
|--------------|--------------|------|------------------------------|
| Holy Light   | Paladin      | 65   | Heal target ally for 200 HP  |
| Resurrect    | Paladin      | 100  | Revive a fallen friendly unit |
| Death Coil   | Death Knight | 50   | Deal 100 damage to target    |
| Animate Dead | Death Knight | 100  | Raise an enemy corpse to fight for you |

Spells add a micro-management layer on top of the macro-economic RTS loop.  A
well-timed Holy Light can save an army; a clutch Animate Dead can turn a lost
fight into a decisive victory.

---

## Inventory, Loot & Crafting

Heroes carry an inventory of up to **6 items** that modify their stats or
provide consumable effects.

### Shop Items

| Item            | Type       | Gold | Effect                    |
|-----------------|------------|------|---------------------------|
| Health Potion   | Consumable | 50   | Restore HP                |
| Mana Potion     | Consumable | 75   | Restore Mana              |
| Sword of Light  | Equipment  | 200  | Increase Attack            |
| Shield of Iron  | Equipment  | 200  | Increase Defense           |
| Ring of Power   | Equipment  | 400  | Increase Attack & Defense  |
| Elixir of Speed | Consumable | 150  | Increase Movement Speed    |

### Crafting

Players can combine items to forge more powerful equipment at a crafting station.

| Recipe                              | Result        |
|-------------------------------------|---------------|
| Sword of Light + Shield of Iron     | Ring of Power |

### Loot Drops

Defeated enemies and neutral creeps may drop random items that can be picked up
by any nearby hero.

---

## Map, Terrain & Environment

### Tile Types

The battlefield is a 2-D tile grid.  Each tile has a type that determines
passability and resource availability.

| Tile      | Passable (Ground) | Passable (Naval) | Resource |
|-----------|:------------------:|:----------------:|:--------:|
| Grass     | ✓                  | ✗                | —        |
| Water     | ✗                  | ✓                | —        |
| Trees     | ✓                  | ✗                | Lumber   |
| Rock      | ✗                  | ✗                | —        |
| Gold Mine | ✓                  | ✗                | Gold     |

### 3-D Terrain

On top of the logical tile grid, the engine supports continuous height maps
(elevation values 0.0–1.0) with auto-computed surface normals for real-time
normal-mapped lighting.  Hills and valleys affect the visual presentation and
reinforce the fantasy atmosphere.

### Day / Night Cycle

A dynamic day/night cycle runs over **600 ticks** per full rotation:

| Phase | Tick Range | Ambient Light |
|-------|------------|---------------|
| Dawn  | 0 – 24 %  | Warm orange ramp-up |
| Day   | 25 – 74 % | Full brightness |
| Dusk  | 75 – 87 % | Cool purple fade |
| Night | 88 – 99 % | Dark blue, reduced visibility |

Ambient RGB values blend smoothly between phases, creating a living battlefield
that rewards players who time attacks to exploit lighting conditions (e.g. night
raids with reduced enemy sight).

---

## Fog of War

Every tile starts in the **hidden** state.  As friendly units and buildings
reveal their surroundings, tiles transition through three states:

| State    | Description |
|----------|-------------|
| Hidden   | Completely black; no information |
| Explored | Terrain visible but units/buildings are not shown unless in sight |
| Visible  | Full real-time information within a unit's sight radius |

Sight radius uses **Manhattan distance** (4 tiles for most ground units, 5–6 for
naval/air units and heroes).  Scouting is essential: you cannot attack what you
cannot see.

---

## Campaign & Missions

The single-player campaign tells the story of the conflict between the Human
Alliance and the Orc Horde across a series of hand-crafted missions.

### Mission Structure

Each mission is defined using an Elixir macro DSL:

- **Name** — display title shown on the campaign map.
- **Objectives** — list of goals the player must complete to win.
- **on_start** — callback that sets up the map, starting units, and resources.
- **on_tick** — callback fired every game tick for scripted events and triggers.
- **on_victory** — callback that awards XP, items, and unlocks the next mission.

### Hero Persistence

Hero XP and inventory carry over between campaign missions, rewarding players who
invest in their heroes early with a powerful late-campaign advantage.

### Scenario Editor

A built-in map and scenario editor allows players and modders to:

- Paint terrain tiles on a mutable grid.
- Place starting units and buildings for each player.
- Configure starting resources.
- Export scenarios for use in custom games or community campaigns.

---

## Multiplayer

### Networking

VibeCraft uses a **TCP-based client/server architecture**:

- **Protocol:** 4-byte length-prefixed binary frames carrying Erlang-encoded
  terms.
- **Server:** A GenServer listening on a configurable port (default 4001) that
  spawns per-connection handlers.
- **Client:** A GenServer that mirrors the Lobby API, allowing seamless
  connection from the game UI.

### Lobby

The multiplayer lobby supports:

- Player registration with unique names.
- Room creation and joining.
- Ready-up handshake before the match begins.

### Ranked Matchmaking

An **Elo-based** rating system drives the ranked ladder:

| Parameter      | Value                                      |
|----------------|--------------------------------------------|
| Initial Rating | 1200                                       |
| K-Factor       | 32                                         |
| Max Difference | 300 (players further apart are not matched) |

Five visible ranks map to rating tiers:

| Rank     | Rating Range |
|----------|-------------|
| Bronze   | < 1300      |
| Silver   | 1300 – 1499 |
| Gold     | 1500 – 1699 |
| Platinum | 1700 – 1899 |
| Diamond  | ≥ 1900      |

---

## AI Opponents

A rule-based AI provides a competent single-player challenge:

1. **Economy** — Trains workers and sends them to gather Gold and Lumber.
2. **Military** — Trains combat units (Grunts) when resources allow.
3. **Aggression** — Moves military units toward the nearest known enemy position.
4. **Combat** — Attacks any adjacent enemy unit automatically.

Future iterations will add difficulty levels, tech-tree awareness, and
spell-casting heroes to the AI.

---

## Replay System

Every multiplayer and skirmish match is recorded as a **tick-indexed event log**.

### Recorded Events

| Event           | Data                                      |
|-----------------|-------------------------------------------|
| unit_moved      | Unit ID, from position, to position       |
| unit_attacked   | Attacker ID, defender ID, damage dealt    |
| spell_cast      | Hero ID, spell name, target, effect       |
| unit_spawned    | Unit type, position, owning player        |
| building_trained| Building ID, unit type queued             |

### Playback

Replays can be loaded and played back at variable speed, allowing players to
study their own games, learn from opponents, or share memorable moments with the
community.

---

## Audio & Visual Style

### Visual Style

- **Original 16×16 pixel art** for all units, buildings, terrain, and UI
  elements.
- All source artwork stored as SVG for clean scaling; rasterised to pixel art at
  build time.
- Palette-driven aesthetic with distinct color identities for each faction.
- **Wavefront OBJ** (`.obj`) for 3-D unit models — plain-text format that
  diffs cleanly in Git and is supported by all major 3-D tools.
- **BVH** (Biovision Hierarchy) for skeletal animations — plain-text
  motion-capture format storing skeleton hierarchy and per-frame joint
  rotations. Git-friendly and universally supported by 3-D tools.

### Audio

- **Original soundtrack** with faction-specific themes.
- Environmental audio (footsteps, sword clashes, spell effects, ambient nature).
- SDL2\_mixer integration for cross-platform audio playback.

---

## Technical Architecture

### Technology Stack

| Concern       | Choice                               |
|---------------|--------------------------------------|
| Language      | Elixir / OTP                         |
| Graphics API  | OpenGL 3.3 Core (via SDL2 NIF)       |
| Audio         | SDL2\_mixer NIF                      |
| Networking    | Elixir GenServer + raw TCP           |
| Build         | Mix + CMake (for NIF C layer)        |
| CI            | GitHub Actions                       |

### Why Elixir?

- **Concurrency** — Lightweight BEAM processes handle AI, networking, rendering,
  and game ticks concurrently without shared-state bugs.
- **Fault Tolerance** — OTP supervisors restart crashed subsystems without
  bringing down the game.
- **Hot Code Reloading** — Ship balance patches and content updates without
  server downtime.
- **Functional Purity** — Immutable game state makes every tick deterministic,
  enabling replays and network synchronisation.

### Module Map

```
VibeCraft (application)
├── Game             — tick loop, state aggregation, victory check
├── Unit             — movement, combat, XP, 3-layer model
├── Building         — training queue, spawn logic
├── Resources        — per-player Gold & Lumber
├── Hero             — leveling, stat progression
├── Spell            — mana-based casting system
├── Inventory        — items, shop, crafting, loot
├── AI               — rule-based opponent
├── Map.Map          — tile grid, fog-of-war
├── Map.Tile         — tile types & passability
├── Map.Loader       — .map file parser
├── Terrain          — 3-D height maps & normals
├── DayNight         — ambient cycle & RGB blending
├── Campaign.Mission — mission DSL & lifecycle
├── Editor           — scenario editor
├── Replay           — event recording & playback
├── Lobby            — room management
├── Matchmaking      — Elo ladder
├── Net.Server       — TCP server
├── Net.Client       — TCP client
├── Net.Protocol     — binary framing
├── GFX.Window       — SDL2 window
├── GFX.Renderer     — OpenGL sprite renderer
├── GFX.NIF          — native bindings
├── Assets.Sprites   — built-in pixel art
├── Assets.Model     — 3-D mesh data (vertices, normals, faces)
├── Assets.ModelLoader — Wavefront OBJ parser
├── Assets.Animation — skeletal animation data (joints, frames)
├── Assets.BvhLoader — BVH animation parser
├── Assets.Loader    — external asset loader
└── Soundtrack       — audio playback
```

---

## Development Roadmap

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 0** | Foundation — repo, CI, GFX bindings, asset pipeline | ✓ Complete |
| **Phase 1** | Playable skirmish with ground units, buildings, resources, AI | ✓ Complete |
| **Phase 2** | Naval/air units, heroes, spells, TCP multiplayer, campaign DSL | ✓ Complete |
| **Phase 3** | 3-D terrain, day/night, inventory, editor, replay, matchmaking | ✓ Complete |
| **Phase 4** | Polish — performance, accessibility, localisation, distribution | In Progress |

See [ROADMAP.md](ROADMAP.md) for detailed task breakdowns.

---

## Appendix: Comparable Titles

VibeCraft occupies the **RTS / RPG hybrid** niche alongside games such as:

- Classic 1990s–2000s real-time strategy titles with hero and item mechanics.
- Modern indie RTS revivals that blend base-building with action-RPG progression.

Our unique angle is the **Elixir/OTP technology stack**, which gives us native
concurrency, fault tolerance, and hot code reloading — capabilities that
traditional C++ engines cannot match without significant infrastructure
investment.

---

*This document is maintained alongside the codebase. For the latest status, see
[STATUS.md](STATUS.md). For contribution guidelines, see
[CONTRIBUTING.md](CONTRIBUTING.md).*
