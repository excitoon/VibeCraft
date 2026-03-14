defmodule VibeCraft.InventoryTest do
  use ExUnit.Case, async: true

  alias VibeCraft.{Inventory, Resources}

  describe "new/0" do
    test "creates an empty inventory with default capacity" do
      inv = Inventory.new()
      assert inv.items == []
      assert inv.capacity == 6
    end
  end

  describe "item_count/1" do
    test "returns 0 for a new inventory" do
      assert Inventory.item_count(Inventory.new()) == 0
    end

    test "returns the number of items after adding" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      assert Inventory.item_count(inv) == 1
    end
  end

  describe "get_item/1" do
    test "returns item map with id injected" do
      item = Inventory.get_item(:health_potion)
      assert item.id == :health_potion
      assert item.name == "Health Potion"
      assert item.category == :consumable
      assert item.cost == 150
      assert item.hp_bonus == 200
    end

    test "raises KeyError for unknown item id" do
      assert_raise KeyError, fn -> Inventory.get_item(:nonexistent_item) end
    end
  end

  describe "add_item/2" do
    test "adds an item to the inventory" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      assert Inventory.item_count(inv) == 1
      assert hd(inv.items).id == :health_potion
    end

    test "allows adding up to capacity" do
      inv = Inventory.new()
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :mana_potion)
      {:ok, inv} = Inventory.add_item(inv, :leather_vest)
      {:ok, inv} = Inventory.add_item(inv, :tower_shield)
      {:ok, inv} = Inventory.add_item(inv, :sword_of_flames)
      {:ok, inv} = Inventory.add_item(inv, :frost_axe)
      assert Inventory.item_count(inv) == 6
    end

    test "returns error when inventory is full" do
      inv = Inventory.new()
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :mana_potion)
      {:ok, inv} = Inventory.add_item(inv, :leather_vest)
      {:ok, inv} = Inventory.add_item(inv, :tower_shield)
      {:ok, inv} = Inventory.add_item(inv, :sword_of_flames)
      {:ok, inv} = Inventory.add_item(inv, :frost_axe)
      assert {:error, :inventory_full} = Inventory.add_item(inv, :ring_of_strength)
    end

    test "duplicate items are allowed" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      assert Inventory.item_count(inv) == 2
    end
  end

  describe "remove_item/2" do
    test "removes the first occurrence of an item" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      assert {:ok, updated, removed} = Inventory.remove_item(inv, :health_potion)
      assert Inventory.item_count(updated) == 0
      assert removed.id == :health_potion
    end

    test "removes only the first occurrence when duplicates exist" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      {:ok, updated, _removed} = Inventory.remove_item(inv, :health_potion)
      assert Inventory.item_count(updated) == 1
    end

    test "returns error when item is not in inventory" do
      assert {:error, :item_not_found} = Inventory.remove_item(Inventory.new(), :health_potion)
    end

    test "removes correct item when inventory has multiple different items" do
      {:ok, inv} = Inventory.add_item(Inventory.new(), :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :mana_potion)
      {:ok, updated, removed} = Inventory.remove_item(inv, :mana_potion)
      assert removed.id == :mana_potion
      assert Enum.all?(updated.items, &(&1.id != :mana_potion))
    end
  end

  describe "generate_loot/1" do
    test "returns items for a known enemy type" do
      loot = Inventory.generate_loot(:grunt)
      assert is_list(loot)
      assert length(loot) > 0
      assert Enum.all?(loot, &is_map/1)
    end

    test "all loot items have valid structure" do
      loot = Inventory.generate_loot(:paladin)

      for item <- loot do
        assert Map.has_key?(item, :id)
        assert Map.has_key?(item, :name)
        assert Map.has_key?(item, :category)
        assert Map.has_key?(item, :cost)
        assert item.category in [:weapon, :armour, :consumable, :artifact]
      end
    end

    test "returns empty list for unknown enemy type" do
      assert Inventory.generate_loot(:unknown_enemy) == []
    end

    test "dragon drops powerful items" do
      loot = Inventory.generate_loot(:dragon)
      ids = Enum.map(loot, & &1.id)
      assert :sword_of_flames in ids or :ring_of_strength in ids
    end
  end

  describe "shop_catalog/0" do
    test "returns a non-empty list of items" do
      catalog = Inventory.shop_catalog()
      assert is_list(catalog)
      assert length(catalog) > 0
    end

    test "all catalog items have valid structure" do
      for item <- Inventory.shop_catalog() do
        assert Map.has_key?(item, :id)
        assert Map.has_key?(item, :name)
        assert Map.has_key?(item, :category)
        assert item.cost > 0
        assert item.category in [:weapon, :armour, :consumable, :artifact]
      end
    end

    test "catalog includes all four item categories" do
      categories = Inventory.shop_catalog() |> Enum.map(& &1.category) |> Enum.uniq()
      assert :weapon in categories
      assert :armour in categories
      assert :consumable in categories
      assert :artifact in categories
    end
  end

  describe "buy_item/3" do
    test "deducts gold and adds item on successful purchase" do
      resources = Resources.new(1000, 0)
      inv = Inventory.new()
      assert {:ok, updated_res, updated_inv} = Inventory.buy_item(resources, inv, :health_potion)
      assert updated_res.gold == 1000 - 150
      assert Inventory.item_count(updated_inv) == 1
    end

    test "returns error when player cannot afford the item" do
      resources = Resources.new(50, 0)
      assert {:error, :insufficient_resources} =
               Inventory.buy_item(resources, Inventory.new(), :plate_armour)
    end

    test "returns error when inventory is full" do
      resources = Resources.new(10_000, 0)
      inv = Inventory.new()
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :mana_potion)
      {:ok, inv} = Inventory.add_item(inv, :leather_vest)
      {:ok, inv} = Inventory.add_item(inv, :tower_shield)
      {:ok, inv} = Inventory.add_item(inv, :sword_of_flames)
      {:ok, inv} = Inventory.add_item(inv, :frost_axe)

      assert {:error, :inventory_full} =
               Inventory.buy_item(resources, inv, :health_potion)
    end

    test "does not deduct gold when inventory is full" do
      resources = Resources.new(10_000, 0)
      inv = Inventory.new()
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      {:ok, inv} = Inventory.add_item(inv, :mana_potion)
      {:ok, inv} = Inventory.add_item(inv, :leather_vest)
      {:ok, inv} = Inventory.add_item(inv, :tower_shield)
      {:ok, inv} = Inventory.add_item(inv, :sword_of_flames)
      {:ok, inv} = Inventory.add_item(inv, :frost_axe)

      {:error, _} = Inventory.buy_item(resources, inv, :health_potion)
      assert resources.gold == 10_000
    end
  end

  describe "craft/2" do
    test "crafts health_potion and mana_potion into elixir_of_fortitude" do
      assert {:ok, item} = Inventory.craft(:health_potion, :mana_potion)
      assert item.id == :elixir_of_fortitude
    end

    test "crafting is commutative — ingredient order does not matter" do
      assert {:ok, item_ab} = Inventory.craft(:health_potion, :mana_potion)
      assert {:ok, item_ba} = Inventory.craft(:mana_potion, :health_potion)
      assert item_ab.id == item_ba.id
    end

    test "returns error for an unknown ingredient combination" do
      assert {:error, :invalid_recipe} = Inventory.craft(:health_potion, :elven_bow)
    end

    test "crafted item has valid structure" do
      {:ok, item} = Inventory.craft(:health_potion, :mana_potion)
      assert Map.has_key?(item, :id)
      assert Map.has_key?(item, :name)
      assert Map.has_key?(item, :category)
      assert item.hp_bonus > 0
    end
  end
end
