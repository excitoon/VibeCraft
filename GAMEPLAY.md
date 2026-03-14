# VibeCraft — Gameplay Reference

This document covers the two playable races, their units, buildings, and the planned hero system.

---

## Races

VibeCraft features two factions, each with their own units and buildings.

### Human Alliance

The Human Alliance relies on disciplined soldiers and industrious peasants.  Workers gather
resources and construct buildings; fighters hold the line in melee combat.

| Unit       | Role    | Produced by  |
|------------|---------|--------------|
| `:peasant` | Worker  | `:town_hall` |
| `:footman` | Fighter | `:barracks`  |

### Orc Horde

The Orc Horde fields savage grunts backed by hard-working peons.  Grunt attacks deal more
damage than their Human counterparts, giving the Horde an aggressive edge.

| Unit    | Role    | Produced by  |
|---------|---------|--------------|
| `:peon` | Worker  | `:town_hall` |
| `:grunt`| Fighter | `:barracks`  |

---

## Units

All units occupy a single tile and move one tile per tick in a cardinal direction.
Ground units can melee-attack any enemy unit on an adjacent tile.

### Ground units

| Type       | Race   | Role    | HP | Attack | Sight | Gold | Lumber | Train (ticks) |
|------------|--------|---------|----|--------|-------|------|--------|---------------|
| `:peasant` | Human  | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| `:footman` | Human  | Fighter | 60 | 6      | 4     | 135  | 0      | 60            |
| `:peon`    | Orc    | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| `:grunt`   | Orc    | Fighter | 60 | 8      | 4     | 100  | 0      | 60            |

**HP** — hit points at full health.  
**Attack** — melee damage dealt per strike.  
**Sight** — fog-of-war reveal radius in tiles.  
**Gold / Lumber** — resource cost to train.  
**Train (ticks)** — game ticks from queue entry to spawn.

#### Worker abilities

Workers (`:peasant`, `:peon`) can harvest resources.  Each trip to a mine or lumber stand
yields **10 gold** or **10 lumber**, deposited back at the nearest town hall.

---

## Buildings

Buildings occupy a single tile and maintain a training queue of up to **5** entries.
Only the front entry counts down each tick; finished units spawn on an adjacent free tile.

| Type         | Race        | HP   | Trains                    |
|--------------|-------------|------|---------------------------|
| `:town_hall` | Both        | 1200 | `:peasant`, `:peon`       |
| `:barracks`  | Both        | 800  | `:footman`, `:grunt`      |

---

## Heroes *(Phase 2 — planned)*

Hero units are powerful named characters that persist across missions and gain experience.
They will be introduced in Phase 2 alongside the spell and campaign systems.

### Planned hero types

| Hero            | Race  | Role              |
|-----------------|-------|-------------------|
| `:paladin`      | Human | Holy warrior      |
| `:death_knight` | Orc   | Dark spellcaster  |

### Hero mechanics (planned)

- **Experience (XP)** — earned by defeating enemy units; heroes level up at XP thresholds.
- **Mana** — a separate resource pool consumed by spells; regenerates over time.
- **Spells** — heroes learn new abilities on level up (e.g. *Holy Light*, *Death and Decay*).
- **Persistence** — hero XP and items carry over between campaign missions.

---

## Resources

Both races share the same resource economy.

| Resource | Starting amount | Gathered by    |
|----------|-----------------|----------------|
| Gold     | 500             | Workers (mines)|
| Lumber   | 200             | Workers (trees)|
