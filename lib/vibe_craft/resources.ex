defmodule VibeCraft.Resources do
  @moduledoc """
  Per-player resource tracking for Gold and Lumber.

  Both resources are non-negative integers.  Spending resources that would
  drive either below zero is rejected.
  """

  @type t :: %__MODULE__{
          gold: non_neg_integer(),
          lumber: non_neg_integer()
        }

  @enforce_keys [:gold, :lumber]
  defstruct [:gold, :lumber]

  @doc "Create a new resource set.  Defaults to 500 gold and 200 lumber."
  @spec new(non_neg_integer(), non_neg_integer()) :: t()
  def new(gold \\ 500, lumber \\ 200) do
    %__MODULE__{gold: gold, lumber: lumber}
  end

  @doc "Add `gold` and `lumber` to `resources`."
  @spec add(t(), non_neg_integer(), non_neg_integer()) :: t()
  def add(%__MODULE__{gold: g, lumber: l}, gold, lumber) do
    %__MODULE__{gold: g + gold, lumber: l + lumber}
  end

  @doc """
  Deduct `gold` and `lumber` from `resources`.

  Returns `{:ok, updated}` when the player can afford the cost, or
  `{:error, :insufficient_resources}` otherwise.
  """
  @spec spend(t(), non_neg_integer(), non_neg_integer()) ::
          {:ok, t()} | {:error, :insufficient_resources}
  def spend(%__MODULE__{gold: g, lumber: l} = res, gold, lumber)
      when g >= gold and l >= lumber do
    {:ok, %{res | gold: g - gold, lumber: l - lumber}}
  end

  def spend(_resources, _gold, _lumber), do: {:error, :insufficient_resources}

  @doc "Return `true` when the player has at least `gold` gold and `lumber` lumber."
  @spec sufficient?(t(), non_neg_integer(), non_neg_integer()) :: boolean()
  def sufficient?(%__MODULE__{gold: g, lumber: l}, gold, lumber) do
    g >= gold and l >= lumber
  end
end
