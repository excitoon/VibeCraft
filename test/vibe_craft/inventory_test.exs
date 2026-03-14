defmodule VibeCraft.InventoryTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Inventory

  defp empty, do: Inventory.new(6)
  defp funded, do: Inventory.add_gold(empty(), 1_000)

  describe "new/1" do
    test "starts with zero items and gold" do
      inv = Inventory.new()
      assert Inventory.size(inv) == 0
      assert inv.gold == 0
    end

    test "accepts a custom capacity" do
      inv = Inventory.new(3)
      assert inv.capacity == 3
    end
  end

  describe "add_item/3" do
    test "adds a new item type" do
      {:ok, inv} = Inventory.add_item(empty(), :health_potion)
      assert Inventory.quantity(inv, :health_potion) == 1
    end

    test "stacks an existing item type" do
      {:ok, inv} = Inventory.add_item(empty(), :health_potion, 3)
      {:ok, inv} = Inventory.add_item(inv, :health_potion, 2)
      assert Inventory.quantity(inv, :health_potion) == 5
    end

    test "returns error when capacity is exceeded with a new item type" do
      inv = Inventory.new(1)
      {:ok, inv} = Inventory.add_item(inv, :health_potion)
      assert {:error, :inventory_full} = Inventory.add_item(inv, :mana_potion)
    end
  end

  describe "remove_item/3" do
    test "decrements quantity" do
      {:ok, inv} = Inventory.add_item(empty(), :health_potion, 3)
      {:ok, inv} = Inventory.remove_item(inv, :health_potion, 2)
      assert Inventory.quantity(inv, :health_potion) == 1
    end

    test "removes the item key when quantity reaches zero" do
      {:ok, inv} = Inventory.add_item(empty(), :health_potion)
      {:ok, inv} = Inventory.remove_item(inv, :health_potion)
      assert Inventory.size(inv) == 0
    end

    test "returns error when item is not held" do
      assert {:error, :insufficient_items} = Inventory.remove_item(empty(), :health_potion)
    end
  end

  describe "add_gold/2" do
    test "increases gold" do
      inv = Inventory.add_gold(empty(), 250)
      assert inv.gold == 250
    end
  end

  describe "buy_from_shop/2" do
    test "deducts gold and adds item on successful purchase" do
      inv = funded()
      {:ok, inv} = Inventory.buy_from_shop(inv, :health_potion)
      assert Inventory.quantity(inv, :health_potion) == 1
      assert inv.gold == 1_000 - 50
    end

    test "returns error when gold is insufficient" do
      assert {:error, :insufficient_gold} = Inventory.buy_from_shop(empty(), :sword_of_light)
    end

    test "returns error for items not sold in the shop" do
      assert {:error, :unknown_item} = Inventory.buy_from_shop(funded(), :ring_of_power)
    end
  end

  describe "craft_item/2" do
    test "crafts ring_of_power from its ingredients" do
      {:ok, inv} = Inventory.add_item(empty(), :sword_of_light)
      {:ok, inv} = Inventory.add_item(inv, :shield_of_iron)
      {:ok, inv} = Inventory.craft_item(inv, :ring_of_power)
      assert Inventory.quantity(inv, :ring_of_power) == 1
      assert Inventory.quantity(inv, :sword_of_light) == 0
      assert Inventory.quantity(inv, :shield_of_iron) == 0
    end

    test "returns error when ingredients are missing" do
      assert {:error, :missing_ingredients} = Inventory.craft_item(empty(), :ring_of_power)
    end

    test "returns error for items with no recipe" do
      assert {:error, :unknown_recipe} = Inventory.craft_item(empty(), :health_potion)
    end
  end

  describe "loot_drop/0" do
    test "returns a valid item type" do
      valid = [:health_potion, :mana_potion, :sword_of_light, :shield_of_iron, :elixir_of_speed]
      drop = Inventory.loot_drop()
      assert drop in valid
    end
  end
end
