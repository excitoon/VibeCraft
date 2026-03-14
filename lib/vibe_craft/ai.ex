defmodule VibeCraft.AI do
  @moduledoc """
  Simple rule-based AI opponent for Phase 1.

  The AI controls `:player2` entities using a fixed priority list each tick:

  1. Move idle workers toward the nearest resource tile.
  2. Enqueue grunt training when resources permit and a barracks exists.
  3. Move combat units one step toward the nearest player-1 position.
  4. Attack adjacent player-1 units.
  """

  alias VibeCraft.{Building, Resources, Unit}
  alias VibeCraft.Map.Map, as: GameMap
  alias VibeCraft.Map.Tile

  @type game_state :: %{
          map: GameMap.t(),
          units: %{pos_integer() => Unit.t()},
          buildings: %{pos_integer() => Building.t()},
          resources: %{Unit.player() => Resources.t()},
          next_id: pos_integer()
        }

  @doc """
  Apply one AI turn for `:player2` and return the updated game state.
  """
  @spec take_turn(game_state()) :: game_state()
  def take_turn(state) do
    state
    |> move_workers_to_resources()
    |> train_combat_units()
    |> move_combat_units()
    |> attack_adjacent_enemies()
  end

  # ── Workers ──────────────────────────────────────────────────────────────

  @spec move_workers_to_resources(game_state()) :: game_state()
  defp move_workers_to_resources(%{units: units, map: map} = state) do
    workers =
      units
      |> Map.values()
      |> Enum.filter(fn u ->
        u.player == :player2 and u.type in [:peon, :peasant] and Unit.alive?(u)
      end)

    Enum.reduce(workers, state, fn worker, acc ->
      case find_nearest_resource(map, worker.position) do
        nil ->
          acc

        target_pos ->
          case step_toward(worker, target_pos, map) do
            {:ok, moved} -> put_in(acc, [:units, worker.id], moved)
            {:error, _} -> acc
          end
      end
    end)
  end

  @spec find_nearest_resource(GameMap.t(), GameMap.position()) :: GameMap.position() | nil
  defp find_nearest_resource(%{tiles: tiles}, {cx, cy}) do
    tiles
    |> Enum.filter(fn {_pos, tile} -> Tile.has_gold?(tile) or Tile.has_lumber?(tile) end)
    |> Enum.min_by(fn {{tc, tr}, _} -> abs(tc - cx) + abs(tr - cy) end, fn -> nil end)
    |> case do
      nil -> nil
      {pos, _tile} -> pos
    end
  end

  # ── Training ─────────────────────────────────────────────────────────────

  @spec train_combat_units(game_state()) :: game_state()
  defp train_combat_units(%{buildings: buildings, resources: resources} = state) do
    p2_barracks =
      buildings
      |> Map.values()
      |> Enum.find(&(&1.player == :player2 and &1.type == :barracks and Building.standing?(&1)))

    case p2_barracks do
      nil ->
        state

      barracks ->
        p2_res = resources[:player2]
        {gold_cost, lumber_cost} = Building.cost_to_train(:grunt)

        if Resources.sufficient?(p2_res, gold_cost, lumber_cost) and
             length(barracks.training_queue) < 3 do
          with {:ok, updated_barracks} <- Building.enqueue_training(barracks, :grunt),
               {:ok, new_resources} <- Resources.spend(p2_res, gold_cost, lumber_cost) do
            state
            |> put_in([:buildings, barracks.id], updated_barracks)
            |> put_in([:resources, :player2], new_resources)
          else
            _ -> state
          end
        else
          state
        end
    end
  end

  # ── Combat movement ───────────────────────────────────────────────────────

  @spec move_combat_units(game_state()) :: game_state()
  defp move_combat_units(%{units: units, map: map} = state) do
    fighters =
      units
      |> Map.values()
      |> Enum.filter(fn u ->
        u.player == :player2 and u.type in [:grunt, :footman] and Unit.alive?(u)
      end)

    p1_positions =
      units
      |> Map.values()
      |> Enum.filter(&(&1.player == :player1 and Unit.alive?(&1)))
      |> Enum.map(& &1.position)

    case p1_positions do
      [] ->
        state

      targets ->
        Enum.reduce(fighters, state, fn fighter, acc ->
          nearest =
            Enum.min_by(targets, fn {tc, tr} ->
              {fc, fr} = fighter.position
              abs(tc - fc) + abs(tr - fr)
            end)

          case step_toward(fighter, nearest, map) do
            {:ok, moved} -> put_in(acc, [:units, fighter.id], moved)
            {:error, _} -> acc
          end
        end)
    end
  end

  # ── Melee attack ──────────────────────────────────────────────────────────

  @spec attack_adjacent_enemies(game_state()) :: game_state()
  defp attack_adjacent_enemies(%{units: units} = state) do
    fighters =
      units
      |> Map.values()
      |> Enum.filter(&(&1.player == :player2 and Unit.alive?(&1)))

    p1_units =
      units
      |> Map.values()
      |> Enum.filter(&(&1.player == :player1 and Unit.alive?(&1)))

    Enum.reduce(fighters, state, fn fighter, acc ->
      case Enum.find(p1_units, &Unit.adjacent_to?(fighter, &1.position)) do
        nil ->
          acc

        enemy ->
          damaged = Unit.attack(fighter, enemy)
          put_in(acc, [:units, enemy.id], damaged)
      end
    end)
  end

  # ── Shared helpers ────────────────────────────────────────────────────────

  @spec step_toward(Unit.t(), GameMap.position(), GameMap.t()) ::
          {:ok, Unit.t()} | {:error, :no_path | :not_adjacent | :impassable | :out_of_bounds}
  defp step_toward(%{position: {cx, cy}} = unit, {tx, ty}, map) do
    best =
      [{cx - 1, cy}, {cx + 1, cy}, {cx, cy - 1}, {cx, cy + 1}]
      |> Enum.filter(fn pos ->
        GameMap.in_bounds?(map, pos) and
          map |> GameMap.tile_at(pos) |> Tile.passable?()
      end)
      |> Enum.min_by(fn {nc, nr} -> abs(nc - tx) + abs(nr - ty) end, fn -> nil end)

    case best do
      nil -> {:error, :no_path}
      pos -> Unit.move(unit, pos, map)
    end
  end
end
