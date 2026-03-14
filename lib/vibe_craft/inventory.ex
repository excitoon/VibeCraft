defmodule VibeCraft.Inventory do
  @moduledoc """
  RPG inventory, loot drops, shop purchases, and item crafting for Phase 3.

  An `Inventory` tracks a hero's carried items by type and quantity.  The
  total number of distinct item stacks is bounded by `capacity`.

  ## Item types

  | Type                | Category   | Shop price  |
  |---------------------|------------|-------------|
  | `:health_potion`    | consumable | 50 gold     |
  | `:mana_potion`      | consumable | 75 gold     |
  | `:sword_of_light`   | equipment  | 400 gold    |
  | `:shield_of_iron`   | equipment  | 300 gold    |
  | `:ring_of_power`    | equipment  | craft only  |
  | `:elixir_of_speed`  | consumable | 125 gold    |

  ## Crafting recipes

  | Output            | Ingredients                             |
  |-------------------|-----------------------------------------|
  | `:ring_of_power`  | `:sword_of_light` + `:shield_of_iron`   |
  """

  @type item_type ::
          :health_potion
          | :mana_potion
          | :sword_of_light
          | :shield_of_iron
          | :ring_of_power
          | :elixir_of_speed

  @type t :: %__MODULE__{
          items: %{item_type() => non_neg_integer()},
          gold: non_neg_integer(),
          capacity: pos_integer()
        }

  @enforce_keys [:capacity]
  defstruct [:capacity, items: %{}, gold: 0]

  @shop_prices %{
    health_potion: 50,
    mana_potion: 75,
    sword_of_light: 400,
    shield_of_iron: 300,
    elixir_of_speed: 125
  }

  @recipes %{
    ring_of_power: [:sword_of_light, :shield_of_iron]
  }

  @loot_table [
    :health_potion,
    :health_potion,
    :mana_potion,
    :elixir_of_speed,
    :sword_of_light,
    :shield_of_iron
  ]

  @doc "Create a new empty inventory with the given item `capacity` (default: 6)."
  @spec new(pos_integer()) :: t()
  def new(capacity \\ 6) do
    %__MODULE__{capacity: capacity, items: %{}, gold: 0}
  end

  @doc "Return the quantity of `item_type` in the inventory (0 when absent)."
  @spec quantity(t(), item_type()) :: non_neg_integer()
  def quantity(%__MODULE__{items: items}, item_type) do
    Map.get(items, item_type, 0)
  end

  @doc "Return the number of distinct item stacks currently held."
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{items: items}), do: map_size(items)

  @doc """
  Add `qty` units of `item_type` to the inventory.

  Returns `{:error, :inventory_full}` when adding a new item type would
  exceed `capacity`.
  """
  @spec add_item(t(), item_type(), pos_integer()) :: {:ok, t()} | {:error, :inventory_full}
  def add_item(%__MODULE__{items: items, capacity: cap} = inv, item_type, qty \\ 1) do
    if Map.has_key?(items, item_type) or map_size(items) < cap do
      new_qty = Map.get(items, item_type, 0) + qty
      {:ok, %{inv | items: Map.put(items, item_type, new_qty)}}
    else
      {:error, :inventory_full}
    end
  end

  @doc """
  Remove `qty` units of `item_type` from the inventory.

  Returns `{:error, :insufficient_items}` when fewer than `qty` are held.
  """
  @spec remove_item(t(), item_type(), pos_integer()) ::
          {:ok, t()} | {:error, :insufficient_items}
  def remove_item(%__MODULE__{items: items} = inv, item_type, qty \\ 1) do
    current = Map.get(items, item_type, 0)

    if current >= qty do
      new_items = update_or_delete(items, item_type, current - qty)
      {:ok, %{inv | items: new_items}}
    else
      {:error, :insufficient_items}
    end
  end

  @doc "Add `amount` gold to the inventory."
  @spec add_gold(t(), non_neg_integer()) :: t()
  def add_gold(%__MODULE__{gold: g} = inv, amount), do: %{inv | gold: g + amount}

  @doc """
  Buy one unit of `item_type` from the shop, spending gold.

  Errors:
  - `{:error, :unknown_item}` — item is not sold in the shop.
  - `{:error, :insufficient_gold}` — not enough gold.
  - `{:error, :inventory_full}` — no free slot for the new item.
  """
  @spec buy_from_shop(t(), item_type()) ::
          {:ok, t()} | {:error, :insufficient_gold | :inventory_full | :unknown_item}
  def buy_from_shop(%__MODULE__{gold: gold} = inv, item_type) do
    case Map.get(@shop_prices, item_type) do
      nil -> {:error, :unknown_item}
      price when gold < price -> {:error, :insufficient_gold}
      price -> add_item(%{inv | gold: gold - price}, item_type)
    end
  end

  @doc """
  Craft `output_type` from its required ingredients.

  Each required ingredient is consumed (quantity 1).  Errors:
  - `{:error, :unknown_recipe}` — no recipe exists for `output_type`.
  - `{:error, :missing_ingredients}` — inventory lacks a required component.
  - `{:error, :inventory_full}` — no room for the crafted item.
  """
  @spec craft_item(t(), item_type()) ::
          {:ok, t()} | {:error, :missing_ingredients | :unknown_recipe | :inventory_full}
  def craft_item(inv, output_type) do
    case Map.get(@recipes, output_type) do
      nil -> {:error, :unknown_recipe}
      ingredients -> craft_from_ingredients(inv, ingredients, output_type)
    end
  end

  @doc """
  Return a random loot item dropped by a defeated enemy.

  The returned atom can be passed directly to `add_item/3`.
  """
  @spec loot_drop() :: item_type()
  def loot_drop, do: Enum.random(@loot_table)

  # ── Private helpers ─────────────────────────────────────────────────────

  @spec craft_from_ingredients(t(), [item_type()], item_type()) ::
          {:ok, t()} | {:error, :missing_ingredients | :inventory_full}
  defp craft_from_ingredients(inv, ingredients, output_type) do
    with {:ok, consumed} <- consume_ingredients(inv, ingredients) do
      add_item(consumed, output_type)
    end
  end

  @spec consume_ingredients(t(), [item_type()]) ::
          {:ok, t()} | {:error, :missing_ingredients}
  defp consume_ingredients(inv, ingredients) do
    Enum.reduce_while(ingredients, {:ok, inv}, fn item, {:ok, acc} ->
      case remove_item(acc, item) do
        {:ok, updated} -> {:cont, {:ok, updated}}
        {:error, :insufficient_items} -> {:halt, {:error, :missing_ingredients}}
      end
    end)
  end

  @spec update_or_delete(%{item_type() => non_neg_integer()}, item_type(), non_neg_integer()) ::
          %{item_type() => non_neg_integer()}
  defp update_or_delete(items, key, 0), do: Map.delete(items, key)
  defp update_or_delete(items, key, qty), do: Map.put(items, key, qty)
end
