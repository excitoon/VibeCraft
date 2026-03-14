defmodule VibeCraft.Building do
  @moduledoc """
  Building data and unit-training queue logic.

  Buildings occupy a single tile.  Each building type can train a fixed set
  of unit types.  Training entries are processed in FIFO order; only the
  front of the queue advances each tick.

  ## Building types

  | Type        | HP   | Trains              |
  |-------------|------|---------------------|
  | `:town_hall`| 1200 | `:peasant`, `:peon` |
  | `:barracks` |  800 | `:footman`, `:grunt` |

  ## Training costs and durations

  | Unit       | Gold | Lumber | Ticks |
  |------------|------|--------|-------|
  | `:footman` | 135  | 0      | 60    |
  | `:peasant` |  75  | 0      | 45    |
  | `:grunt`   | 100  | 0      | 60    |
  | `:peon`    |  75  | 0      | 45    |
  """

  alias VibeCraft.Unit

  @type player :: Unit.player()
  @type building_type :: :town_hall | :barracks

  @type training_entry :: %{unit_type: Unit.unit_type(), ticks_remaining: pos_integer()}

  @type t :: %__MODULE__{
          id: pos_integer(),
          type: building_type(),
          player: player(),
          position: {non_neg_integer(), non_neg_integer()},
          hp: non_neg_integer(),
          max_hp: pos_integer(),
          training_queue: [training_entry()]
        }

  @max_queue 5

  @stats %{
    town_hall: %{hp: 1_200},
    barracks: %{hp: 800}
  }

  @trainable %{
    town_hall: [:peasant, :peon],
    barracks: [:footman, :grunt]
  }

  @costs %{
    footman: {135, 0},
    peasant: {75, 0},
    grunt: {100, 0},
    peon: {75, 0}
  }

  @train_ticks %{
    footman: 60,
    peasant: 45,
    grunt: 60,
    peon: 45
  }

  @enforce_keys [:id, :type, :player, :position, :hp, :max_hp]
  defstruct [:id, :type, :player, :position, :hp, :max_hp, training_queue: []]

  @doc "Create a new building of `type` for `player` at `position`."
  @spec new(pos_integer(), building_type(), player(), {non_neg_integer(), non_neg_integer()}) ::
          t()
  def new(id, type, player, position) do
    %{hp: hp} = @stats[type]

    %__MODULE__{
      id: id,
      type: type,
      player: player,
      position: position,
      hp: hp,
      max_hp: hp
    }
  end

  @doc "Return `true` when the building has HP greater than zero."
  @spec standing?(t()) :: boolean()
  def standing?(%__MODULE__{hp: hp}), do: hp > 0

  @doc "Return the `{gold, lumber}` cost to train `unit_type`."
  @spec cost_to_train(Unit.unit_type()) :: {non_neg_integer(), non_neg_integer()}
  def cost_to_train(unit_type), do: Map.fetch!(@costs, unit_type)

  @doc "Return the list of unit types this building can train."
  @spec can_train(t()) :: [Unit.unit_type()]
  def can_train(%__MODULE__{type: btype}), do: Map.fetch!(@trainable, btype)

  @doc """
  Add `unit_type` to the training queue of `building`.

  Returns `{:ok, updated_building}` on success, or:
  - `{:error, :cannot_train}` when the building does not produce that unit type.
  - `{:error, :queue_full}` when the queue already has #{@max_queue} entries.
  """
  @spec enqueue_training(t(), Unit.unit_type()) ::
          {:ok, t()} | {:error, :cannot_train | :queue_full}
  def enqueue_training(%__MODULE__{type: btype, training_queue: q} = building, unit_type) do
    allowed = Map.fetch!(@trainable, btype)

    cond do
      unit_type not in allowed ->
        {:error, :cannot_train}

      length(q) >= @max_queue ->
        {:error, :queue_full}

      true ->
        entry = %{unit_type: unit_type, ticks_remaining: Map.fetch!(@train_ticks, unit_type)}
        {:ok, %{building | training_queue: q ++ [entry]}}
    end
  end

  @doc """
  Advance the training queue by one tick.

  Only the front of the queue counts down.  Returns
  `{updated_building, completed_unit_types}` where `completed_unit_types` is
  a (possibly empty) list of unit types that finished training this tick.
  """
  @spec tick_training(t()) :: {t(), [Unit.unit_type()]}
  def tick_training(%__MODULE__{training_queue: []} = building), do: {building, []}

  def tick_training(%__MODULE__{training_queue: [head | rest]} = building) do
    updated_head = %{head | ticks_remaining: head.ticks_remaining - 1}

    if updated_head.ticks_remaining <= 0 do
      {%{building | training_queue: rest}, [head.unit_type]}
    else
      {%{building | training_queue: [updated_head | rest]}, []}
    end
  end
end
