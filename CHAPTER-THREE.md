# Chapter III

Chapter III is VibeCraft's flagship experience and the primary development
target.  It transforms the battlefield into a living, three-dimensional world
and adds a full RPG item system, a scenario editor, match replays, and
competitive ranked matchmaking.

---

## Setting

The world has gained depth — literally.  Rolling hills, deep valleys, and
craggy cliffs replace the flat tile grids of earlier chapters.  A dynamic
day/night cycle paints the battlefield in warm dawn light, harsh midday sun,
cool dusk hues, and the deep blue of night.  Heroes have grown into legendary
figures who collect rare loot, shop for powerful gear, and forge legendary
equipment at the crafting station.  The community builds its own campaigns with
a built-in scenario editor, and every match is recorded for post-game analysis.
A ranked Elo ladder ensures every competitive game is a fair test of skill.

---

## 3-D Terrain

On top of the logical tile grid, the engine supports continuous **height maps**
(elevation values 0.0–1.0) with auto-computed surface normals for real-time
**normal-mapped lighting**.  Hills and valleys affect the visual presentation
and reinforce the fantasy atmosphere.

Key features:

- Procedural and hand-painted elevation data.
- Per-vertex normals computed from the height field.
- Real-time directional lighting reacts to surface orientation.
- Strategic implications: high ground provides visual dominance.

---

## Day / Night Cycle

A dynamic day/night cycle runs over **600 ticks** per full rotation:

| Phase | Tick Range | Ambient Light               |
|-------|------------|-----------------------------|
| Dawn  | 0 – 24 %   | Warm orange ramp-up         |
| Day   | 25 – 74 %  | Full brightness             |
| Dusk  | 75 – 87 %  | Cool purple fade            |
| Night | 88 – 99 %  | Dark blue, reduced visibility|

Ambient RGB values blend smoothly between phases, creating a living battlefield
that rewards players who time attacks to exploit lighting conditions (e.g. night
raids with reduced enemy sight).

---

## Inventory, Loot & Crafting

Heroes carry an inventory of up to **6 items** that modify their stats or
provide consumable effects.

### Shop Items

| Item            | Type       | Gold | Effect                   |
|-----------------|------------|------|--------------------------|
| Health Potion   | Consumable | 50   | Restore HP               |
| Mana Potion     | Consumable | 75   | Restore Mana             |
| Sword of Light  | Equipment  | 200  | Increase Attack          |
| Shield of Iron  | Equipment  | 200  | Increase Defense         |
| Ring of Power   | Equipment  | 400  | Increase Attack & Defense|
| Elixir of Speed | Consumable | 150  | Increase Movement Speed  |

### Crafting

Players can combine items to forge more powerful equipment at a crafting station.

| Recipe                            | Result        |
|-----------------------------------|---------------|
| Sword of Light + Shield of Iron   | Ring of Power |

### Loot Drops

Defeated enemies and neutral creeps may drop random items that can be picked up
by any nearby hero.

---

## Scenario Editor

A built-in map and scenario editor allows players and modders to:

- Paint terrain tiles on a mutable grid.
- Place starting units and buildings for each player.
- Configure starting resources.
- Export scenarios for use in custom games or community campaigns.

Scenarios are defined using an Elixir macro DSL, making them scriptable and
version-controllable.

---

## Replay System

Every multiplayer and skirmish match is recorded as a **tick-indexed event log**.

### Recorded Events

| Event            | Data                                     |
|------------------|------------------------------------------|
| unit_moved       | Unit ID, from position, to position      |
| unit_attacked    | Attacker ID, defender ID, damage dealt   |
| spell_cast       | Hero ID, spell name, target, effect      |
| unit_spawned     | Unit type, position, owning player       |
| building_trained | Building ID, unit type queued            |

### Playback

Replays can be loaded and played back at variable speed, allowing players to
study their own games, learn from opponents, or share memorable moments with
the community.

---

## Ranked Matchmaking

An **Elo-based** rating system drives the ranked ladder:

| Parameter      | Value                                       |
|----------------|---------------------------------------------|
| Initial Rating | 1200                                        |
| K-Factor       | 32                                          |
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

## Audio

- **Original soundtrack** with faction-specific themes.
- Environmental audio (footsteps, sword clashes, spell effects, ambient nature).
- SDL2\_mixer integration for cross-platform audio playback.

---

## Full Feature Summary

Chapter III includes everything from Chapters I and II, plus:

| Feature                | Description                                              |
|------------------------|----------------------------------------------------------|
| 3-D terrain            | Height maps with normal-mapped lighting                  |
| Day/night cycle        | 600-tick ambient cycle affecting visibility and mood      |
| Inventory & crafting   | 6-slot hero inventory, shop, loot drops, item recipes    |
| Scenario editor        | Paint terrain, place units, configure resources, export  |
| Replay system          | Tick-indexed event recording and variable-speed playback |
| Ranked matchmaking     | Elo ladder with five visible rank tiers                  |
| Original soundtrack    | Faction themes and environmental audio via SDL2\_mixer   |
