defmodule VibeCraft do
  @moduledoc """
  VibeCraft — an original RTS game with RPG elements.

  See `VibeCraft.Demo` for the Phase-0 prototype render loop.

  ## Phase 1 — Version I Mechanics

  The Phase 1 modules implement the core single-player skirmish engine:

  - `VibeCraft.Map.Tile` — tile type definitions (grass, water, trees, rock,
    gold mine) with passability and resource helpers.
  - `VibeCraft.Map.Map` — 2-D tile grid with fog-of-war state
    (`:hidden` / `:explored` / `:visible`).
  - `VibeCraft.Map.Loader` — load maps from plain-text `.map` files.
  - `VibeCraft.Resources` — per-player Gold and Lumber tracking.
  - `VibeCraft.Unit` — unit data (footman, peasant, grunt, peon) with
    movement and melee-combat logic.
  - `VibeCraft.Building` — building data (town hall, barracks) with unit
    training queues.
  - `VibeCraft.Game` — top-level game state: tick loop, spawn, fog update,
    and victory detection.
  - `VibeCraft.AI` — simple rule-based opponent for player 2.
  - `VibeCraft.Assets.Sprites` — extended with terrain tiles, unit sprites,
    and building sprites.
  """
end
