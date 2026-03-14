defmodule VibeCraft.Unit do
  @moduledoc """
  Unit data and movement / melee-combat logic.

  Units occupy a single tile.  Ground units move one tile per tick in a
  cardinal direction and can melee-attack adjacent enemy units.

  ## Unit types

  | Type       | Role          | HP | Attack |
  |------------|---------------|----|--------|
  | `:footman` | Human fighter | 60 | 6      |
  | `:peasant` | Human worker  | 30 | 3      |
  | `:grunt`   | Orc fighter   | 60 | 8      |
  | `:peon`    | Orc worker    | 30 | 3      |
  """

  alias VibeCraft.Map.{Map, Tile}

  @type player :: :player1 | :player2
  @type unit_type :: :footman | :peasant | :grunt | :peon

  @type t :: %__MODULE__{
          id: pos_integer(),
          type: unit_type(),
          player: player(),
          position: Map.position(),
          hp: non_neg_integer(),
          max_hp: pos_integer(),
          attack: pos_integer(),
          sight_radius: pos_integer(),
          carrying_gold: non_neg_integer(),
          carrying_lumber: non_neg_integer()
        }

  @enforce_keys [:id, :type, :player, :position, :hp, :max_hp, :attack, :sight_radius]
  defstruct [
    :id,
    :type,
    :player,
    :position,
    :hp,
    :max_hp,
    :attack,
    :sight_radius,
    carrying_gold: 0,
    carrying_lumber: 0
  ]

  @stats %{
    footman: %{hp: 60, attack: 6, sight_radius: 4},
    peasant: %{hp: 30, attack: 3, sight_radius: 4},
    grunt: %{hp: 60, attack: 8, sight_radius: 4},
    peon: %{hp: 30, attack: 3, sight_radius: 4}
  }

  @doc "Create a new unit of the given type for `player` at `position`."
  @spec new(pos_integer(), unit_type(), player(), Map.position()) :: t()
  def new(id, type, player, position) do
    %{hp: hp, attack: attack, sight_radius: sight_radius} = @stats[type]

    %__MODULE__{
      id: id,
      type: type,
      player: player,
      position: position,
      hp: hp,
      max_hp: hp,
      attack: attack,
      sight_radius: sight_radius
    }
  end

  @doc "Return `true` when the unit has HP greater than zero."
  @spec alive?(t()) :: boolean()
  def alive?(%__MODULE__{hp: hp}), do: hp > 0

  @doc "Return `true` when `unit` and `other` belong to different players."
  @spec enemy?(t(), t()) :: boolean()
  def enemy?(%__MODULE__{player: p1}, %__MODULE__{player: p2}), do: p1 != p2

  @doc """
  Move the unit one tile to `target`.

  Returns `{:ok, updated_unit}` when `target` is exactly one step away and
  the destination tile is passable.  Otherwise returns `{:error, reason}`
  where reason is one of `:not_adjacent`, `:out_of_bounds`, or `:impassable`.
  """
  @spec move(t(), Map.position(), Map.t()) ::
          {:ok, t()} | {:error, :not_adjacent | :impassable | :out_of_bounds}
  def move(%__MODULE__{position: {cx, cy}} = unit, {tx, ty} = target, map) do
    distance = abs(tx - cx) + abs(ty - cy)

    cond do
      distance != 1 ->
        {:error, :not_adjacent}

      not Map.in_bounds?(map, target) ->
        {:error, :out_of_bounds}

      not passable?(Map.tile_at(map, target)) ->
        {:error, :impassable}

      true ->
        {:ok, %{unit | position: target}}
    end
  end

  @doc """
  Apply one melee attack from `attacker` to `defender`.

  Returns the updated `defender` with HP reduced (minimum 0).
  """
  @spec attack(t(), t()) :: t()
  def attack(%__MODULE__{attack: dmg}, defender) do
    %{defender | hp: max(0, defender.hp - dmg)}
  end

  @doc "Return `true` when `unit` is immediately adjacent (4-directional) to `pos`."
  @spec adjacent_to?(t(), Map.position()) :: boolean()
  def adjacent_to?(%__MODULE__{position: {cx, cy}}, {tx, ty}) do
    abs(tx - cx) + abs(ty - cy) == 1
  end

  @doc """
  Return the per-trip harvest amounts `{gold, lumber}` for a worker unit.

  Non-worker types return `{0, 0}`.
  """
  @spec harvest_amount(unit_type()) :: {non_neg_integer(), non_neg_integer()}
  def harvest_amount(type) when type in [:peasant, :peon], do: {10, 10}
  def harvest_amount(_type), do: {0, 0}

  @spec passable?(Tile.t() | nil) :: boolean()
  defp passable?(nil), do: false
  defp passable?(tile), do: Tile.passable?(tile)
end
