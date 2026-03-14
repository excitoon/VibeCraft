# VibeCraft Roadmap

## What Are Elixir GFX Bindings?

Elixir runs on the BEAM virtual machine, which excels at concurrency and fault tolerance but has no built-in access to GPU hardware or graphics APIs. **Elixir GFX bindings** are thin Elixir wrappers around native graphics libraries — implemented as NIFs (Native Implemented Functions) or C ports — that let the BEAM call into OpenGL, Vulkan, SDL, or similar APIs. In practice this means:

- A small C/Rust layer that calls the underlying graphics API.
- Elixir NIF modules that expose those calls as ordinary Elixir functions.
- All game-logic code (units, AI, networking, maps) stays in pure Elixir; only the render hot-path touches native code.

This keeps the architecture clean: BEAM handles concurrency and state; the NIF layer handles pixels.

---

## Project Phases

### Phase 0 — Foundation ✓

- [x] Repository skeleton, LICENSE, CONTRIBUTING guide
- [x] CI pipeline (formatting, Credo, Dialyzer)
- [x] GFX bindings prototype — SDL2 window + OpenGL context via NIF
- [x] Asset pipeline — load and display a single original sprite

### Phase 1 — Version I Mechanics

Goal: a playable single-player skirmish with Version I rules.

- [ ] Map loader (tile-based terrain, fog of war)
- [ ] Unit system — movement, basic melee combat
- [ ] Resource gathering (Gold, Lumber)
- [ ] Building construction and unit training queue
- [ ] Simple AI opponent
- [ ] Original art set: terrain tiles, at least two unit types, two building types

### Phase 2 — Version II Mechanics

Goal: extend Version I with naval and air units plus a campaign framework.

- [ ] Naval units and sea-lane pathfinding
- [ ] Air units and altitude layer
- [ ] Spell / ability system (mana-based)
- [ ] Hero units with experience and leveling
- [ ] Campaign mission scripting DSL (Elixir macros)
- [ ] Multiplayer lobby over TCP (BEAM distribution or raw sockets)
- [ ] Expanded original art set

### Phase 3 — Version III Experience (primary target)

Goal: full feature parity with a modern RTS/RPG hybrid.

- [ ] 3-D terrain rendering (height maps, normal mapping)
- [ ] Day/night cycle and dynamic lighting
- [ ] RPG elements: inventory, loot, shops, item crafting
- [ ] Custom map / scenario editor
- [ ] Replay recording and playback
- [ ] Ranked matchmaking and ladder
- [ ] Full original soundtrack and voice-over stubs

### Phase 4 — Polish and Release

- [ ] Performance profiling and NIF optimization
- [ ] Accessibility options (colorblind mode, remappable keys)
- [ ] Localization framework
- [ ] Steam / itch.io distribution packaging
- [ ] Public beta and bug-fix sprint

---

## Technology Stack

| Concern | Choice |
|---|---|
| Language | Elixir / OTP |
| Graphics API | OpenGL 3.3 Core (via SDL2 NIF) |
| Audio | SDL2\_mixer NIF |
| Networking | Elixir GenServer + raw TCP |
| Build | Mix + CMake (for NIF layer) |
| CI | GitHub Actions |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding standards and PR guidelines.
