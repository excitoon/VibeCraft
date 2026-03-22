# Chapter II

Chapter II expands the conflict to every dimension — land, sea, and sky.  It
introduces naval and air units, hero characters with experience and spells,
a full campaign system, and TCP multiplayer.

---

## Setting

The war that began on the ground now spreads across oceans and into the skies.
Warships contest sea lanes while dragons and gryphon riders clash above the
clouds.  Powerful heroes emerge on both sides — legendary warriors and dark
spellcasters whose growing strength can turn the tide of battle.  The conflict
is no longer confined to a single skirmish: a multi-mission campaign tells the
story of the war, and for the first time players can challenge each other over
the network.

---

## Factions

### Human Alliance

The Alliance gains the **Gryphon** as a flying unit and the **Paladin** as a
hero.  The Paladin excels at sustaining the army with powerful healing magic,
complementing the Alliance's defensive playstyle.

**New strengths:** Healing and resurrection spells, aerial scouting.

### Orc Horde

The Horde gains the **Dragon** — a devastating air unit — and the **Death
Knight** as a hero.  The Death Knight channels dark magic to destroy and
reanimate fallen foes, doubling down on the Horde's aggressive identity.

**New strengths:** Superior air firepower, corpse manipulation.

---

## New Unit Types

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

Units now belong to one of three **layers** — ground, naval, or air — each with
its own movement rules and passability constraints.

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
  differentiator.

---

## Spells & Abilities

Heroes learn spells as they level up.  Each spell costs mana and has an
immediate effect.

| Spell        | Hero         | Mana | Effect                                  |
|--------------|--------------|------|-----------------------------------------|
| Holy Light   | Paladin      | 65   | Heal target ally for 200 HP             |
| Resurrect    | Paladin      | 100  | Revive a fallen friendly unit           |
| Death Coil   | Death Knight | 50   | Deal 100 damage to target               |
| Animate Dead | Death Knight | 100  | Raise an enemy corpse to fight for you  |

Spells add a micro-management layer on top of the macro-economic RTS loop.  A
well-timed Holy Light can save an army; a clutch Animate Dead can turn a lost
fight into a decisive victory.

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

Hero XP and inventory carry over between campaign missions, rewarding players
who invest in their heroes early with a powerful late-campaign advantage.

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

---

## What Chapter II Does Not Include

The following features are **not** part of Chapter II and are introduced in
Chapter III:

- 3-D terrain and height maps
- Day/night cycle and dynamic lighting
- Inventory, loot, shops, and item crafting
- Map/scenario editor
- Replay recording and playback
- Ranked matchmaking and Elo ladder
