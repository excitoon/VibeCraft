# VibeCraft — Status & ETA

## Current Status

**Phase 0 — Foundation ✓ (complete)**

The project skeleton, CI pipeline, GFX bindings (SDL2 + OpenGL via NIF), and the initial asset
pipeline are all finished. The engine can open a window, initialise an OpenGL 3.3 context, and
render a single original sprite. All CI checks (formatting, Credo, Dialyzer) pass.

---

## Estimated Timeline

All dates are best-effort targets. They will be revised as contributors join or leave and as the
scope of each phase becomes clearer. Progress is tracked in [ROADMAP.md](ROADMAP.md).

| Milestone | Target | Notes |
|---|---|---|
| Phase 1 — Version I Mechanics | Q3 2026 | Playable single-player skirmish (map, units, resources, simple AI) |
| Phase 2 — Version II Mechanics | Q1 2027 | Naval & air units, hero system, TCP multiplayer lobby |
| Phase 3 — Version III Experience | Q3 2027 | 3-D terrain, RPG elements, map editor, ranked matchmaking |
| Phase 4 — Polish & Release | Q4 2027 | Performance, accessibility, localisation, distribution packaging |
| **Public Release** | **Q4 2027** | Steam / itch.io release after public beta and bug-fix sprint |

### Phase 1 detail (next up)

| Task | Status |
|---|---|
| Map loader (tile-based terrain, fog of war) | Not started |
| Unit system — movement, basic melee combat | Not started |
| Resource gathering (Gold, Lumber) | Not started |
| Building construction & unit training queue | Not started |
| Simple AI opponent | Not started |
| Original art set (terrain, 2 unit types, 2 building types) | Not started |

---

## How to Help

Every contribution moves the timeline forward. See [CONTRIBUTING.md](CONTRIBUTING.md) for coding
standards and how to open a pull request.
