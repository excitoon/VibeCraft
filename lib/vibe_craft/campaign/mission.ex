defmodule VibeCraft.Campaign.Mission do
  @moduledoc """
  Macro DSL for defining VibeCraft campaign missions.

  A mission module describes a single campaign scenario: its display name,
  victory objectives, and lifecycle callbacks that are invoked by the game
  engine at key moments.

  ## Defining a mission

      defmodule MyGame.Missions.TheFirstStrike do
        use VibeCraft.Campaign.Mission

        mission_name "The First Strike"

        objective :destroy_all_enemies
        objective :survive_10_ticks

        @impl VibeCraft.Campaign.Mission
        def on_start(game) do
          # Set up the initial game state for this mission.
          game
        end

        @impl VibeCraft.Campaign.Mission
        def on_tick(game, _tick) do
          # React to each game tick.
          game
        end
      end

  ## Mission lifecycle

  | Callback          | When called                                |
  |-------------------|--------------------------------------------|
  | `c:on_start/1`    | Once, immediately before the first tick    |
  | `c:on_tick/2`     | Every tick while the mission is ongoing    |
  | `c:on_victory/1`  | Once, when a `:victory` status is reached  |

  All callbacks receive and return a `VibeCraft.Game.t()` struct so that
  missions can inspect or mutate game state at each stage.

  ## Objectives

  Objectives are atoms that describe what a player must accomplish.  The
  game engine is responsible for checking them; the DSL merely records the
  declarations so they can be retrieved at runtime via `c:objectives/0`.

  Predefined objective atoms:

  - `:destroy_all_enemies` — eliminate every enemy unit and building
  - `:survive_N_ticks`     — keep at least one friendly unit alive for N ticks
  - `:collect_N_gold`      — accumulate N total gold
  - `:build_barracks`      — construct a barracks building
  """

  @doc """
  Return the mission's display name.
  """
  @callback name() :: String.t()

  @doc """
  Return the list of objective atoms declared for this mission.
  """
  @callback objectives() :: [atom()]

  @doc """
  Called once before the first tick.  May add units, set resources, etc.
  """
  @callback on_start(game :: term()) :: term()

  @doc """
  Called every tick while the mission status is `:ongoing`.
  """
  @callback on_tick(game :: term(), tick :: non_neg_integer()) :: term()

  @doc """
  Called once when a `:victory` status is detected.
  """
  @callback on_victory(game :: term()) :: term()

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour VibeCraft.Campaign.Mission

      import VibeCraft.Campaign.Mission, only: [mission_name: 1, objective: 1]

      @mission_objectives []

      @before_compile VibeCraft.Campaign.Mission

      @impl VibeCraft.Campaign.Mission
      def on_start(game), do: game

      @impl VibeCraft.Campaign.Mission
      def on_tick(game, _tick), do: game

      @impl VibeCraft.Campaign.Mission
      def on_victory(game), do: game

      defoverridable on_start: 1, on_tick: 2, on_victory: 1
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @impl VibeCraft.Campaign.Mission
      def objectives, do: @mission_objectives
    end
  end

  @doc """
  Declare the display name for this mission.

  Must be called exactly once at the top of the mission module.

      mission_name "A Dark Portal Opens"
  """
  defmacro mission_name(name) do
    quote do
      @impl VibeCraft.Campaign.Mission
      def name, do: unquote(name)
    end
  end

  @doc """
  Register a victory objective for this mission.

  May be called multiple times; objectives are accumulated in declaration
  order and returned by `c:objectives/0`.

      objective :destroy_all_enemies
      objective :survive_10_ticks
  """
  defmacro objective(atom) do
    quote do
      @mission_objectives @mission_objectives ++ [unquote(atom)]
    end
  end
end
