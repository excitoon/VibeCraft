defmodule VibeCraft.Unit do
  @moduledoc """
  Unit data and movement / melee-combat logic.

  Units occupy a single tile.  Ground units move one tile per tick in a
  cardinal direction and can melee-attack adjacent enemy units.  Naval units
  move on water tiles, and air units fly over any terrain.

  ## Phase 1 unit types (ground layer)

  | Type           | Role               | HP  | Attack |
  |----------------|--------------------|-----|--------|
  | `:footman`     | Human fighter      | 60  | 6      |
  | `:peasant`     | Human worker       | 30  | 3      |
  | `:grunt`       | Orc fighter        | 60  | 8      |
  | `:peon`        | Orc worker         | 30  | 3      |

  ## Phase 2 naval unit types (naval layer)

  | Type           | Role               | HP  | Attack |
  |----------------|--------------------|-----|--------|
  | `:destroyer`   | Naval fighter      | 100 | 10     |
  | `:battleship`  | Heavy naval gun    | 150 | 15     |
  | `:oil_tanker`  | Naval worker       | 60  | 0      |
  | `:transport`   | Troop transport    | 80  | 0      |

  ## Phase 2 air unit types (air layer)

  | Type        | Role            | HP  | Attack |
  |-------------|-----------------|-----|--------|
  | `:gryphon`  | Human air unit  | 80  | 12     |
  | `:dragon`   | Orc air unit    | 120 | 16     |

  ## Phase 2 hero unit types (ground layer with mana)

  | Type            | Role             | HP  | Attack | Mana |
  |-----------------|------------------|-----|--------|------|
  | `:paladin`      | Human hero       | 150 | 12     | 200  |
  | `:death_knight` | Orc hero         | 150 | 15     | 200  |

  ## Orc castes

  Orc units belong to social castes accessible via `orc_caste/1`.

  | Caste      | Unit types              |
  |------------|-------------------------|
  | `:warrior` | `:grunt`, `:dragon`     |
  | `:worker`  | `:peon`                 |
  | `:warlock` | `:death_knight`         |
  """

  alias VibeCraft.Map.{Map, Tile}

  @type player :: :player1 | :player2
  @type layer :: :ground | :naval | :air
  @type orc_caste :: :warrior | :worker | :warlock
  @type unit_type ::
          :footman
          | :peasant
          | :grunt
          | :peon
          | :destroyer
          | :battleship
          | :oil_tanker
          | :transport
          | :gryphon
          | :dragon
          | :paladin
          | :death_knight

  @type t :: %__MODULE__{
          id: pos_integer(),
          type: unit_type(),
          player: player(),
          position: Map.position(),
          hp: non_neg_integer(),
          max_hp: pos_integer(),
          attack: non_neg_integer(),
          sight_radius: pos_integer(),
          layer: layer(),
          mana: non_neg_integer(),
          max_mana: non_neg_integer(),
          xp: non_neg_integer(),
          level: pos_integer(),
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
    layer: :ground,
    mana: 0,
    max_mana: 0,
    xp: 0,
    level: 1,
    carrying_gold: 0,
    carrying_lumber: 0
  ]

  @stats %{
    # Phase 1 — ground units
    footman: %{hp: 60, attack: 6, sight_radius: 4, layer: :ground, max_mana: 0},
    peasant: %{hp: 30, attack: 3, sight_radius: 4, layer: :ground, max_mana: 0},
    grunt: %{hp: 60, attack: 8, sight_radius: 4, layer: :ground, max_mana: 0},
    peon: %{hp: 30, attack: 3, sight_radius: 4, layer: :ground, max_mana: 0},
    # Phase 2 — naval units
    destroyer: %{hp: 100, attack: 10, sight_radius: 5, layer: :naval, max_mana: 0},
    battleship: %{hp: 150, attack: 15, sight_radius: 6, layer: :naval, max_mana: 0},
    oil_tanker: %{hp: 60, attack: 0, sight_radius: 4, layer: :naval, max_mana: 0},
    transport: %{hp: 80, attack: 0, sight_radius: 4, layer: :naval, max_mana: 0},
    # Phase 2 — air units
    gryphon: %{hp: 80, attack: 12, sight_radius: 6, layer: :air, max_mana: 0},
    dragon: %{hp: 120, attack: 16, sight_radius: 6, layer: :air, max_mana: 0},
    # Phase 2 — hero units (ground, with mana)
    paladin: %{hp: 150, attack: 12, sight_radius: 5, layer: :ground, max_mana: 200},
    death_knight: %{hp: 150, attack: 15, sight_radius: 5, layer: :ground, max_mana: 200}
  }

  @doc "Create a new unit of the given type for `player` at `position`."
  @spec new(pos_integer(), unit_type(), player(), Map.position()) :: t()
  def new(id, type, player, position) do
    %{hp: hp, attack: attack, sight_radius: sight_radius, layer: layer, max_mana: max_mana} =
      @stats[type]

    %__MODULE__{
      id: id,
      type: type,
      player: player,
      position: position,
      hp: hp,
      max_hp: hp,
      attack: attack,
      sight_radius: sight_radius,
      layer: layer,
      mana: max_mana,
      max_mana: max_mana
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
  the destination tile is passable for the unit's layer.  Otherwise returns
  `{:error, reason}` where reason is one of `:not_adjacent`, `:out_of_bounds`,
  or `:impassable`.

  - Ground units require a `:grass` tile.
  - Naval units require a `:water` tile.
  - Air units may move over any tile.
  """
  @spec move(t(), Map.position(), Map.t()) ::
          {:ok, t()} | {:error, :not_adjacent | :impassable | :out_of_bounds}
  def move(%__MODULE__{position: {cx, cy}, layer: layer} = unit, {tx, ty} = target, map) do
    distance = abs(tx - cx) + abs(ty - cy)

    cond do
      distance != 1 ->
        {:error, :not_adjacent}

      not Map.in_bounds?(map, target) ->
        {:error, :out_of_bounds}

      not passable_for_layer?(Map.tile_at(map, target), layer) ->
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

  @doc """
  Spend `cost` mana from `unit`.

  Returns `{:ok, updated_unit}` when the unit has sufficient mana, or
  `{:error, :insufficient_mana}` otherwise.
  """
  @spec spend_mana(t(), non_neg_integer()) :: {:ok, t()} | {:error, :insufficient_mana}
  def spend_mana(%__MODULE__{mana: mana} = unit, cost) when mana >= cost do
    {:ok, %{unit | mana: mana - cost}}
  end

  def spend_mana(_unit, _cost), do: {:error, :insufficient_mana}

  @doc """
  Regenerate one point of mana for units that have a mana pool.

  No-op for units with `max_mana == 0`.
  """
  @spec tick_mana(t()) :: t()
  def tick_mana(%__MODULE__{max_mana: 0} = unit), do: unit

  def tick_mana(%__MODULE__{mana: mana, max_mana: max_mana} = unit) do
    %{unit | mana: min(mana + 1, max_mana)}
  end

  @doc """
  Add `xp_gained` experience points to `unit`.

  The returned unit has its `xp` field updated.  Actual level-up logic is
  handled by `VibeCraft.Hero.gain_xp/2` which calls this function and then
  applies stat increases.
  """
  @spec add_xp(t(), non_neg_integer()) :: t()
  def add_xp(%__MODULE__{xp: xp} = unit, xp_gained), do: %{unit | xp: xp + xp_gained}

  @doc """
  Return the orc caste for an orc `unit_type`, or `nil` for non-orc types.

  ## Orc castes

  | Caste      | Unit types              |
  |------------|-------------------------|
  | `:warrior` | `:grunt`, `:dragon`     |
  | `:worker`  | `:peon`                 |
  | `:warlock` | `:death_knight`         |
  """
  @spec orc_caste(unit_type()) :: orc_caste() | nil
  def orc_caste(type) when type in [:grunt, :dragon], do: :warrior
  def orc_caste(:peon), do: :worker
  def orc_caste(:death_knight), do: :warlock
  def orc_caste(_type), do: nil

  @spec passable_for_layer?(Tile.t() | nil, layer()) :: boolean()
  defp passable_for_layer?(nil, _layer), do: false
  defp passable_for_layer?(tile, :ground), do: Tile.passable?(tile)
  defp passable_for_layer?(tile, :naval), do: Tile.naval_passable?(tile)
  defp passable_for_layer?(_tile, :air), do: true
end
