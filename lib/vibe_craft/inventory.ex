defmodule VibeCraft.Inventory do
  @default_capacity 6

  @moduledoc """
  RPG inventory system for Phase 3.

  Manages item definitions, hero item slots, loot generation, the in-game
  shop, and item-crafting recipes.

  ## Item categories

  | Category      | Examples                                   |
  |---------------|--------------------------------------------|
  | `:weapon`     | Sword of Flames, Frost Axe, Elven Bow      |
  | `:armour`      | Plate Armour, Leather Vest, Tower Shield   |
  | `:consumable` | Health Potion, Mana Potion, Elixir of Speed|
  | `:artifact`   | Ring of Strength, Amulet of Wisdom         |

  ## Item stats

  Each item carries four optional stat bonuses:

  - `attack_bonus` — added to the bearer's attack rating.
  - `armour_bonus`  — added to the bearer's armour rating.
  - `hp_bonus`     — added to the bearer's maximum HP when equipped.
  - `mana_bonus`   — added to the bearer's maximum mana when equipped.

  ## Capacity

  Every hero inventory has a fixed `capacity` (default #{@default_capacity}
  slots).  Adding an item beyond that limit returns
  `{:error, :inventory_full}`.

  ## Loot

  `generate_loot/1` accepts an enemy category atom (`:grunt`, `:footman`,
  `:destroyer`, `:dragon`, `:death_knight`, `:paladin`) and returns the list
  of items that enemy type typically drops.

  ## Shop

  `shop_catalog/0` returns all items available for purchase.  `buy_item/3`
  deducts the gold cost from a `VibeCraft.Resources` struct and adds the
  item to an inventory.

  ## Crafting

  `craft/2` accepts two item ids and returns `{:ok, crafted_item}` when a
  valid recipe exists, or `{:error, :invalid_recipe}` otherwise.

  ## Usage

      iex> inv = Inventory.new()
      iex> {:ok, inv} = Inventory.add_item(inv, :health_potion)
      iex> Inventory.item_count(inv)
      1
  """

  alias VibeCraft.Resources

  @type item_category :: :weapon | :armour | :consumable | :artifact

  @type item :: %{
          id: atom(),
          name: String.t(),
          category: item_category(),
          cost: non_neg_integer(),
          attack_bonus: integer(),
          armour_bonus: integer(),
          hp_bonus: integer(),
          mana_bonus: integer()
        }

  @type t :: %__MODULE__{
          items: [item()],
          capacity: pos_integer()
        }

  @enforce_keys [:items, :capacity]
  defstruct [:items, :capacity]

  # ── Item catalogue ──────────────────────────────────────────────────────

  @catalogue %{
    # ── Weapons ──────────────────────────────────────────────────────────
    sword_of_flames: %{
      name: "Sword of Flames",
      category: :weapon,
      cost: 500,
      attack_bonus: 6,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 0
    },
    frost_axe: %{
      name: "Frost Axe",
      category: :weapon,
      cost: 450,
      attack_bonus: 5,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 0
    },
    elven_bow: %{
      name: "Elven Bow",
      category: :weapon,
      cost: 400,
      attack_bonus: 7,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 0
    },
    shadow_dagger: %{
      name: "Shadow Dagger",
      category: :weapon,
      cost: 350,
      attack_bonus: 4,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 0
    },
    # ── Armour ───────────────────────────────────────────────────────────
    plate_armour: %{
      name: "Plate Armour",
      category: :armour,
      cost: 600,
      attack_bonus: 0,
      armour_bonus: 8,
      hp_bonus: 50,
      mana_bonus: 0
    },
    tower_shield: %{
      name: "Tower Shield",
      category: :armour,
      cost: 550,
      attack_bonus: 0,
      armour_bonus: 6,
      hp_bonus: 25,
      mana_bonus: 0
    },
    leather_vest: %{
      name: "Leather Vest",
      category: :armour,
      cost: 250,
      attack_bonus: 0,
      armour_bonus: 3,
      hp_bonus: 15,
      mana_bonus: 0
    },
    # ── Consumables ──────────────────────────────────────────────────────
    health_potion: %{
      name: "Health Potion",
      category: :consumable,
      cost: 150,
      attack_bonus: 0,
      armour_bonus: 0,
      hp_bonus: 200,
      mana_bonus: 0
    },
    mana_potion: %{
      name: "Mana Potion",
      category: :consumable,
      cost: 150,
      attack_bonus: 0,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 150
    },
    elixir_of_fortitude: %{
      name: "Elixir of Fortitude",
      category: :consumable,
      cost: 300,
      attack_bonus: 0,
      armour_bonus: 0,
      hp_bonus: 500,
      mana_bonus: 0
    },
    # ── Artifacts ────────────────────────────────────────────────────────
    ring_of_strength: %{
      name: "Ring of Strength",
      category: :artifact,
      cost: 700,
      attack_bonus: 5,
      armour_bonus: 2,
      hp_bonus: 75,
      mana_bonus: 0
    },
    amulet_of_wisdom: %{
      name: "Amulet of Wisdom",
      category: :artifact,
      cost: 700,
      attack_bonus: 0,
      armour_bonus: 0,
      hp_bonus: 0,
      mana_bonus: 200
    },
    boots_of_speed: %{
      name: "Boots of Speed",
      category: :artifact,
      cost: 500,
      attack_bonus: 0,
      armour_bonus: 1,
      hp_bonus: 25,
      mana_bonus: 25
    }
  }

  # ── Loot tables ─────────────────────────────────────────────────────────

  @loot_tables %{
    grunt: [:health_potion, :leather_vest],
    footman: [:health_potion, :shadow_dagger],
    destroyer: [:frost_axe, :tower_shield],
    dragon: [:sword_of_flames, :ring_of_strength],
    death_knight: [:amulet_of_wisdom, :mana_potion, :frost_axe],
    paladin: [:ring_of_strength, :elixir_of_fortitude, :plate_armour]
  }

  # ── Crafting recipes ────────────────────────────────────────────────────

  # Each recipe: {ingredient_1, ingredient_2} => result_item_id
  @recipes %{
    {:health_potion, :mana_potion} => :elixir_of_fortitude,
    {:sword_of_flames, :ring_of_strength} => :amulet_of_wisdom,
    {:frost_axe, :leather_vest} => :plate_armour,
    {:tower_shield, :shadow_dagger} => :boots_of_speed
  }

  # ── Public API ──────────────────────────────────────────────────────────

  @doc "Create a new empty inventory with the default #{@default_capacity}-slot capacity."
  @spec new() :: t()
  def new, do: %__MODULE__{items: [], capacity: @default_capacity}

  @doc "Return the number of items currently in `inventory`."
  @spec item_count(t()) :: non_neg_integer()
  def item_count(%__MODULE__{items: items}), do: length(items)

  @doc """
  Return the item definition for `item_id`.

  Raises `KeyError` when `item_id` is not in the catalogue.
  """
  @spec get_item(atom()) :: item()
  def get_item(item_id) do
    attrs = Map.fetch!(@catalogue, item_id)
    Map.put(attrs, :id, item_id)
  end

  @doc """
  Add `item_id` to `inventory`.

  Returns `{:ok, updated_inventory}` on success, or
  `{:error, :inventory_full}` when the inventory is at capacity.
  """
  @spec add_item(t(), atom()) :: {:ok, t()} | {:error, :inventory_full}
  def add_item(%__MODULE__{items: items, capacity: cap} = inv, item_id)
      when length(items) < cap do
    item = get_item(item_id)
    {:ok, %{inv | items: items ++ [item]}}
  end

  def add_item(%__MODULE__{}, _item_id), do: {:error, :inventory_full}

  @doc """
  Remove the first occurrence of `item_id` from `inventory`.

  Returns `{:ok, updated_inventory, removed_item}` on success, or
  `{:error, :item_not_found}` when the inventory does not contain the item.
  """
  @spec remove_item(t(), atom()) :: {:ok, t(), item()} | {:error, :item_not_found}
  def remove_item(%__MODULE__{items: items} = inv, item_id) do
    case Enum.split_while(items, &(&1.id != item_id)) do
      {_before, []} ->
        {:error, :item_not_found}

      {before, [removed | rest]} ->
        {:ok, %{inv | items: before ++ rest}, removed}
    end
  end

  @doc """
  Return the list of items dropped by an enemy of `enemy_type`.

  Returns an empty list for unrecognised enemy types.
  """
  @spec generate_loot(atom()) :: [item()]
  def generate_loot(enemy_type) do
    item_ids = Map.get(@loot_tables, enemy_type, [])
    Enum.map(item_ids, &get_item/1)
  end

  @doc "Return all items available for purchase in the shop."
  @spec shop_catalog() :: [item()]
  def shop_catalog do
    Enum.map(@catalogue, fn {id, attrs} -> Map.put(attrs, :id, id) end)
  end

  @doc """
  Purchase `item_id` from the shop.

  Deducts the item's gold cost from `resources` and adds the item to
  `inventory`.

  Returns `{:ok, updated_resources, updated_inventory}` on success.
  Returns `{:error, :insufficient_resources}` when the player cannot afford
  the item, or `{:error, :inventory_full}` when the inventory is at capacity.
  """
  @spec buy_item(Resources.t(), t(), atom()) ::
          {:ok, Resources.t(), t()} | {:error, :insufficient_resources | :inventory_full}
  def buy_item(%Resources{} = resources, %__MODULE__{} = inventory, item_id) do
    item = get_item(item_id)

    with {:ok, updated_resources} <- Resources.spend(resources, item.cost, 0),
         {:ok, updated_inventory} <- add_item(inventory, item_id) do
      {:ok, updated_resources, updated_inventory}
    end
  end

  @doc """
  Combine `item_id_a` and `item_id_b` using a crafting recipe.

  Returns `{:ok, crafted_item}` when a recipe exists for the pair (in either
  order), or `{:error, :invalid_recipe}` otherwise.
  """
  @spec craft(atom(), atom()) :: {:ok, item()} | {:error, :invalid_recipe}
  def craft(item_id_a, item_id_b) do
    key_ab = {item_id_a, item_id_b}
    key_ba = {item_id_b, item_id_a}

    case Map.get(@recipes, key_ab) || Map.get(@recipes, key_ba) do
      nil -> {:error, :invalid_recipe}
      result_id -> {:ok, get_item(result_id)}
    end
  end
end
