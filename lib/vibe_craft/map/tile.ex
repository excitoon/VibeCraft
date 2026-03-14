defmodule VibeCraft.Map.Tile do
  @moduledoc """
  Tile type definitions for VibeCraft maps.

  Each tile has a type that determines traversability and whether it holds
  a harvestable resource.
  """

  @type tile_type :: :grass | :water | :trees | :rock | :gold_mine

  @type t :: %__MODULE__{
          type: tile_type(),
          resource_amount: non_neg_integer()
        }

  @enforce_keys [:type]
  defstruct [:type, resource_amount: 0]

  @doc """
  Create a new tile of the given type.

  Gold mine tiles start with 5 000 gold; tree tiles start with 100 lumber.
  """
  @spec new(tile_type()) :: t()
  def new(:gold_mine), do: %__MODULE__{type: :gold_mine, resource_amount: 5_000}
  def new(:trees), do: %__MODULE__{type: :trees, resource_amount: 100}
  def new(type), do: %__MODULE__{type: type}

  @doc "Returns `true` if ground units may walk on this tile."
  @spec passable?(t()) :: boolean()
  def passable?(%__MODULE__{type: type}), do: type == :grass

  @doc "Returns `true` if this tile holds harvestable lumber."
  @spec has_lumber?(t()) :: boolean()
  def has_lumber?(%__MODULE__{type: :trees}), do: true
  def has_lumber?(_), do: false

  @doc "Returns `true` if this tile holds a gold mine."
  @spec has_gold?(t()) :: boolean()
  def has_gold?(%__MODULE__{type: :gold_mine}), do: true
  def has_gold?(_), do: false
end
