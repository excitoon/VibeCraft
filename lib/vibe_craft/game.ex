defmodule VibeCraft.Game do
  @moduledoc """
  Top-level game state for a VibeCraft skirmish.

  A `Game` struct holds the map, all units and buildings keyed by integer ID,
  per-player resources, and a monotonic tick counter.  Game logic is applied
  via pure functions that transform one `Game` into an updated `Game`.

  ## Starting a game

      {:ok, map} = VibeCraft.Map.Loader.load("priv/maps/skirmish.map")
      game  = Game.new(map)
      {game, _th} = Game.add_building(game, :town_hall, :player1, {1, 1})
      {game, _u}  = Game.add_unit(game, :peasant, :player1, {2, 1})
      game = Game.tick(game)
  """

  alias VibeCraft.{AI, Building, Resources, Unit}
  alias VibeCraft.Map.Map, as: GameMap

  @type player :: Unit.player()
  @type status :: :ongoing | {:victory, player()} | :draw

  @type t :: %__MODULE__{
          map: GameMap.t(),
          units: %{pos_integer() => Unit.t()},
          buildings: %{pos_integer() => Building.t()},
          resources: %{player() => Resources.t()},
          tick: non_neg_integer(),
          next_id: pos_integer(),
          status: status()
        }

  @enforce_keys [:map]
  defstruct [
    :map,
    units: %{},
    buildings: %{},
    resources: %{player1: Resources.new(), player2: Resources.new()},
    tick: 0,
    next_id: 1,
    status: :ongoing
  ]

  @doc "Create a new game with the given map."
  @spec new(GameMap.t()) :: t()
  def new(map), do: %__MODULE__{map: map}

  @doc "Add a unit to the game, assigning it the next available ID."
  @spec add_unit(t(), Unit.unit_type(), player(), GameMap.position()) :: {t(), Unit.t()}
  def add_unit(%__MODULE__{next_id: id} = game, type, player, position) do
    unit = Unit.new(id, type, player, position)
    {%{game | units: Map.put(game.units, id, unit), next_id: id + 1}, unit}
  end

  @doc "Add a building to the game, assigning it the next available ID."
  @spec add_building(t(), Building.building_type(), player(), GameMap.position()) ::
          {t(), Building.t()}
  def add_building(%__MODULE__{next_id: id} = game, type, player, position) do
    building = Building.new(id, type, player, position)
    {%{game | buildings: Map.put(game.buildings, id, building), next_id: id + 1}, building}
  end

  @doc """
  Move `unit` one tile to `target_pos`.

  Returns `{:ok, updated_game}` or `{:error, reason}`.
  """
  @spec move_unit(t(), Unit.t(), GameMap.position()) :: {:ok, t()} | {:error, term()}
  def move_unit(game, unit, target_pos) do
    case Unit.move(unit, target_pos, game.map) do
      {:ok, moved} -> {:ok, %{game | units: Map.put(game.units, unit.id, moved)}}
      error -> error
    end
  end

  @doc """
  Have `attacker` deal one melee strike to `defender`.

  Dead units are removed from the game.
  """
  @spec attack(t(), Unit.t(), Unit.t()) :: t()
  def attack(game, attacker, defender) do
    damaged = Unit.attack(attacker, defender)

    units =
      if Unit.alive?(damaged),
        do: Map.put(game.units, defender.id, damaged),
        else: Map.delete(game.units, defender.id)

    %{game | units: units}
  end

  @doc """
  Enqueue training of `unit_type` in `building`, spending player resources.

  Returns `{:ok, updated_game}` or `{:error, reason}`.
  """
  @spec train_unit(t(), Building.t(), Unit.unit_type()) :: {:ok, t()} | {:error, term()}
  def train_unit(game, building, unit_type) do
    {gold_cost, lumber_cost} = Building.cost_to_train(unit_type)
    p_resources = game.resources[building.player]

    with {:ok, new_resources} <- Resources.spend(p_resources, gold_cost, lumber_cost),
         {:ok, updated_building} <- Building.enqueue_training(building, unit_type) do
      game = %{
        game
        | resources: Map.put(game.resources, building.player, new_resources),
          buildings: Map.put(game.buildings, building.id, updated_building)
      }

      {:ok, game}
    end
  end

  @doc """
  Advance the game by one tick.

  Per-tick operations, in order:
  1. Advance all building training queues; spawn newly trained units.
  2. Remove dead units (HP ≤ 0).
  3. Update fog of war from player 1's positions.
  4. Run the AI for player 2.
  5. Check and record a victory/draw condition.
  6. Increment the tick counter.

  No-ops when the game is already decided.
  """
  @spec tick(t()) :: t()
  def tick(%__MODULE__{status: status} = game) when status != :ongoing, do: game

  def tick(game) do
    game
    |> advance_training_queues()
    |> remove_dead_units()
    |> update_fog_of_war()
    |> ai_turn()
    |> check_victory()
    |> Map.update!(:tick, &(&1 + 1))
  end

  # ── Private helpers ─────────────────────────────────────────────────────

  @spec advance_training_queues(t()) :: t()
  defp advance_training_queues(%{buildings: buildings} = game) do
    {updated_buildings, spawns} =
      Enum.reduce(buildings, {%{}, []}, fn {id, building}, {bmap, units} ->
        {updated, trained} = Building.tick_training(building)
        entries = Enum.map(trained, fn ut -> {building, ut} end)
        {Map.put(bmap, id, updated), units ++ entries}
      end)

    Enum.reduce(spawns, %{game | buildings: updated_buildings}, fn {building, unit_type}, g ->
      case find_spawn_position(g, building.position) do
        nil -> g
        pos -> elem(add_unit(g, unit_type, building.player, pos), 0)
      end
    end)
  end

  @spec find_spawn_position(t(), GameMap.position()) :: GameMap.position() | nil
  defp find_spawn_position(%{map: map, units: units}, building_pos) do
    occupied = units |> Map.values() |> MapSet.new(& &1.position)

    map
    |> GameMap.adjacent(building_pos)
    |> Enum.find(fn pos ->
      tile = GameMap.tile_at(map, pos)
      not is_nil(tile) and VibeCraft.Map.Tile.passable?(tile) and pos not in occupied
    end)
  end

  @spec remove_dead_units(t()) :: t()
  defp remove_dead_units(%{units: units} = game) do
    %{game | units: Map.filter(units, fn {_id, u} -> Unit.alive?(u) end)}
  end

  @spec update_fog_of_war(t()) :: t()
  defp update_fog_of_war(%{units: units, buildings: buildings, map: map} = game) do
    p1_positions =
      (Map.values(units) ++ Map.values(buildings))
      |> Enum.filter(&(&1.player == :player1))
      |> Enum.map(& &1.position)

    %{game | map: GameMap.reveal(map, p1_positions, 4)}
  end

  @spec ai_turn(t()) :: t()
  defp ai_turn(game) do
    ai_state = %{
      map: game.map,
      units: game.units,
      buildings: game.buildings,
      resources: game.resources,
      next_id: game.next_id
    }

    updated = AI.take_turn(ai_state)

    %{
      game
      | units: updated.units,
        buildings: updated.buildings,
        resources: updated.resources,
        next_id: updated.next_id
    }
  end

  @spec check_victory(t()) :: t()
  defp check_victory(%{units: units, buildings: buildings} = game) do
    p1_alive = any_alive?(units, buildings, :player1)
    p2_alive = any_alive?(units, buildings, :player2)

    status =
      case {p1_alive, p2_alive} do
        {false, false} -> :draw
        {false, true} -> {:victory, :player2}
        {true, false} -> {:victory, :player1}
        {true, true} -> :ongoing
      end

    %{game | status: status}
  end

  @spec any_alive?(
          %{pos_integer() => Unit.t()},
          %{pos_integer() => Building.t()},
          player()
        ) :: boolean()
  defp any_alive?(units, buildings, player) do
    Enum.any?(units, fn {_id, u} -> u.player == player and Unit.alive?(u) end) or
      Enum.any?(buildings, fn {_id, b} -> b.player == player and Building.standing?(b) end)
  end
end
