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

### Phase 1 — Chapter I Mechanics

Goal: a playable single-player skirmish with Chapter I rules.

- [x] Map loader (tile-based terrain, fog of war)
- [x] Unit system — movement, basic melee combat
- [x] Resource gathering (Gold, Lumber)
- [x] Building construction and unit training queue
- [x] Simple AI opponent
- [x] Original art set: terrain tiles, at least two unit types, two building types

### Phase 2 — Chapter II Mechanics

Goal: extend Chapter I with naval and air units plus a campaign framework.

- [x] Naval units and sea-lane pathfinding
- [x] Air units and altitude layer
- [x] Spell / ability system (mana-based)
- [x] Hero units with experience and leveling
- [x] Campaign mission scripting DSL (Elixir macros)
- [x] Multiplayer lobby over TCP (BEAM distribution or raw sockets)
- [x] Expanded original art set

### Phase 3 — Chapter III Experience (primary target)

Goal: full feature parity with a modern RTS/RPG hybrid.

- [x] 3-D terrain rendering (height maps, normal mapping)
- [x] Day/night cycle and dynamic lighting
- [x] RPG elements: inventory, loot, shops, item crafting
- [x] Custom map / scenario editor
- [x] Replay recording and playback
- [x] Ranked matchmaking and ladder
- [x] Full original soundtrack and voice-over stubs

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

## Reference Implementations

The following projects serve as research references for engine design, mechanics, and platform compatibility.

### 1. Original Game

The original commercial RTS title (Chapter I through Chapter III) that VibeCraft draws its mechanical inspiration from.

### 2. Dedicated Open-Source RTS Engine Re-implementations

Community-built engines that re-implement the core RTS mechanics from scratch:

- **Mod Engine** — A Java-based engine built on [LibGDX](https://libgdx.com/). Designed for modding and requires the legal original game assets to function.
- **Warsmash** — An Android port/fork of Mod Engine specifically targeting mobile devices.
- **Stratagus** — A free, cross-platform RTS game engine capable of running various strategy game rulesets; often used in re-implementation contexts.

### 3. Windows Compatibility Layers (Mobile / Linux)

General-purpose Windows-on-Linux/Android solutions that can run the native Windows game client on alternative operating systems:

- **Winlator** — An Android application based on [Wine](https://www.winehq.org/) and Box86/Box64 for running Windows titles.
- **Exagear** — An Android application widely used to run older Windows games through binary translation.
- **Mobox** — A Windows-emulation layer for Android optimized for gaming performance.

### 4. Legacy LAN / Netplay Platforms

- **Garena** — A popular platform historically used to play the original game over emulated local area networks.
- **MAMEHub** — An open-source extension of [MAME](https://www.mamedev.org/) that adds cross-platform netplay support for a wide range of titles.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding standards and PR guidelines.
