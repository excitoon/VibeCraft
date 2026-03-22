# Chapter I

Chapter I is the foundational VibeCraft experience — a real-time strategy game
fought entirely on land between two asymmetric factions.

---

## Setting

The conflict begins on the ground.  The **Human Alliance** and the **Orc Horde**
compete for dominance across tile-based battlefields of grass, forests, rocky
outcrops, and gold mines.  There is no sea, no sky, and no magic — only steel,
lumber, and the will to survive.

---

## Factions

### Human Alliance

The Human Alliance relies on disciplined soldiers and industrious peasants.
Workers gather resources and construct buildings; fighters hold the line in
melee combat.

**Strengths:** Balanced unit stats, reliable economy.
**Weaknesses:** Lower raw damage output compared to the Horde.

### Orc Horde

The Orc Horde fields savage grunts backed by hard-working peons.  Grunt attacks
deal more damage than their Human counterparts, giving the Horde an aggressive
edge.

**Strengths:** High burst damage, aggressive tempo.
**Weaknesses:** Less staying power in prolonged engagements.

---

## Units

All units occupy a single tile and move one tile per tick in a cardinal direction
(north, south, east, west).

### Ground Units

| Type     | Race  | Role    | HP | Attack | Sight | Gold | Lumber | Train (ticks) |
|----------|-------|---------|----|--------|-------|------|--------|---------------|
| Peasant  | Human | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| Footman  | Human | Fighter | 60 | 6      | 4     | 135  | 0      | 60            |
| Peon     | Orc   | Worker  | 30 | 3      | 4     | 75   | 0      | 45            |
| Grunt    | Orc   | Fighter | 60 | 8      | 4     | 100  | 0      | 60            |

### Worker Abilities

Workers (Peasant, Peon) can harvest resources.  Each trip to a mine or lumber
stand yields **10 Gold** or **10 Lumber**, deposited back at the nearest town
hall.

---

## Buildings

Buildings occupy a single tile and maintain a first-in-first-out training queue
of up to **5** entries.  Only the front entry counts down each tick; finished
units spawn on an adjacent free tile.

| Type      | Race | HP   | Trains         |
|-----------|------|------|----------------|
| Town Hall | Both | 1200 | Peasant / Peon |
| Barracks  | Both | 800  | Footman / Grunt|

---

## Resources

Both factions share the same resource economy.

| Resource | Starting Amount | Gathered By      |
|----------|-----------------|------------------|
| Gold     | 500             | Workers (mines)  |
| Lumber   | 200             | Workers (trees)  |

Resource management is the backbone of every strategic decision.  Gold funds
military units, while Lumber is required for advanced structures.  Controlling
map resources — especially contested gold mines — is the key to mid-game
dominance.

---

## Map & Terrain

The battlefield is a 2-D tile grid.  Each tile has a type that determines
passability and resource availability.

| Tile      | Passable | Resource |
|-----------|:--------:|:--------:|
| Grass     | ✓        | —        |
| Trees     | ✓        | Lumber   |
| Rock      | ✗        | —        |
| Gold Mine | ✓        | Gold     |

---

## Fog of War

Every tile starts in the **hidden** state.  As friendly units and buildings
reveal their surroundings, tiles transition through three states:

| State    | Description                                                      |
|----------|------------------------------------------------------------------|
| Hidden   | Completely black; no information                                 |
| Explored | Terrain visible but units/buildings are not shown unless in sight|
| Visible  | Full real-time information within a unit's sight radius          |

Sight radius uses **Manhattan distance** (4 tiles for ground units).  Scouting
is essential: you cannot attack what you cannot see.

---

## AI Opponent

A rule-based AI provides a competent single-player challenge:

1. **Economy** — Trains workers and sends them to gather Gold and Lumber.
2. **Military** — Trains combat units when resources allow.
3. **Aggression** — Moves military units toward the nearest known enemy position.
4. **Combat** — Attacks any adjacent enemy unit automatically.

---

## Core Gameplay Loop

```
Gather ──► Build ──► Train ──► Scout ──► Fight ──► Expand
  ▲                                                   │
  └───────────────────────────────────────────────────┘
```

The loop runs on a **tick-based simulation** where every game tick advances
movement, combat, and training queues simultaneously.

**Victory condition:** Eliminate all enemy units and buildings.

---

## What Chapter I Does Not Include

The following features are **not** part of Chapter I and are introduced in later
chapters:

- Naval and air units (Chapter II)
- Heroes, experience, and leveling (Chapter II)
- Spells and mana (Chapter II)
- Campaign missions and story (Chapter II)
- Multiplayer networking (Chapter II)
- 3-D terrain and height maps (Chapter III)
- Day/night cycle (Chapter III)
- Inventory, loot, shops, and crafting (Chapter III)
- Map/scenario editor (Chapter III)
- Replay system (Chapter III)
- Ranked matchmaking (Chapter III)
