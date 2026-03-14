defmodule VibeCraft.ResourcesTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Resources

  describe "new/2" do
    test "defaults to 500 gold and 200 lumber" do
      res = Resources.new()
      assert res.gold == 500
      assert res.lumber == 200
    end

    test "accepts custom starting amounts" do
      res = Resources.new(100, 50)
      assert res.gold == 100
      assert res.lumber == 50
    end
  end

  describe "add/3" do
    test "increases gold and lumber" do
      res = Resources.new(100, 50)
      updated = Resources.add(res, 25, 10)
      assert updated.gold == 125
      assert updated.lumber == 60
    end

    test "adding zero does not change values" do
      res = Resources.new(100, 50)
      assert Resources.add(res, 0, 0) == res
    end
  end

  describe "spend/3" do
    test "deducts exact cost" do
      res = Resources.new(200, 100)
      assert {:ok, updated} = Resources.spend(res, 200, 100)
      assert updated.gold == 0
      assert updated.lumber == 0
    end

    test "deducts partial cost leaving remainder" do
      res = Resources.new(500, 200)
      assert {:ok, updated} = Resources.spend(res, 135, 0)
      assert updated.gold == 365
      assert updated.lumber == 200
    end

    test "returns error when gold is insufficient" do
      res = Resources.new(50, 200)
      assert {:error, :insufficient_resources} = Resources.spend(res, 100, 0)
    end

    test "returns error when lumber is insufficient" do
      res = Resources.new(500, 10)
      assert {:error, :insufficient_resources} = Resources.spend(res, 0, 50)
    end

    test "returns error when both resources are insufficient" do
      res = Resources.new(0, 0)
      assert {:error, :insufficient_resources} = Resources.spend(res, 1, 1)
    end
  end

  describe "sufficient?/3" do
    test "returns true when player can afford the cost" do
      res = Resources.new(200, 100)
      assert Resources.sufficient?(res, 200, 100)
    end

    test "returns true when cost is zero" do
      res = Resources.new(0, 0)
      assert Resources.sufficient?(res, 0, 0)
    end

    test "returns false when gold is insufficient" do
      res = Resources.new(50, 200)
      refute Resources.sufficient?(res, 100, 0)
    end

    test "returns false when lumber is insufficient" do
      res = Resources.new(500, 10)
      refute Resources.sufficient?(res, 0, 50)
    end
  end
end
