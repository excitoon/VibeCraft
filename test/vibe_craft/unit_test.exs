defmodule VibeCraft.UnitTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Map.{Map, Tile}
  alias VibeCraft.Unit

  # A 3×3 all-grass map for movement tests.
  defp grass_map do
    rows = for _ <- 0..2, do: for(_ <- 0..2, do: Tile.new(:grass))
    Map.new(rows)
  end

  # A 3×3 map with a water tile at {1, 0} for impassable tests.
  defp blocked_map do
    rows = [
      [Tile.new(:grass), Tile.new(:water), Tile.new(:grass)],
      [Tile.new(:grass), Tile.new(:grass), Tile.new(:grass)],
      [Tile.new(:grass), Tile.new(:grass), Tile.new(:grass)]
    ]

    Map.new(rows)
  end

  describe "new/4" do
    test "creates a footman with correct stats" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert unit.hp == 60
      assert unit.max_hp == 60
      assert unit.attack == 6
      assert unit.sight_radius == 4
      assert unit.player == :player1
      assert unit.position == {0, 0}
    end

    test "creates a peasant with correct stats" do
      unit = Unit.new(1, :peasant, :player1, {0, 0})
      assert unit.hp == 30
      assert unit.attack == 3
    end

    test "creates a grunt with correct stats" do
      unit = Unit.new(1, :grunt, :player2, {0, 0})
      assert unit.hp == 60
      assert unit.attack == 8
    end

    test "creates a peon with correct stats" do
      unit = Unit.new(1, :peon, :player2, {0, 0})
      assert unit.hp == 30
      assert unit.attack == 3
    end
  end

  describe "alive?/1" do
    test "returns true when hp > 0" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert Unit.alive?(unit)
    end

    test "returns false when hp == 0" do
      unit = %{Unit.new(1, :footman, :player1, {0, 0}) | hp: 0}
      refute Unit.alive?(unit)
    end
  end

  describe "enemy?/2" do
    test "units of different players are enemies" do
      u1 = Unit.new(1, :footman, :player1, {0, 0})
      u2 = Unit.new(2, :grunt, :player2, {1, 0})
      assert Unit.enemy?(u1, u2)
    end

    test "units of the same player are not enemies" do
      u1 = Unit.new(1, :footman, :player1, {0, 0})
      u2 = Unit.new(2, :peasant, :player1, {1, 0})
      refute Unit.enemy?(u1, u2)
    end
  end

  describe "move/3" do
    test "moves to an adjacent passable tile" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      map = grass_map()
      assert {:ok, moved} = Unit.move(unit, {1, 0}, map)
      assert moved.position == {1, 0}
    end

    test "returns error for non-adjacent target" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert {:error, :not_adjacent} = Unit.move(unit, {2, 0}, grass_map())
    end

    test "returns error when target is out of bounds" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert {:error, :out_of_bounds} = Unit.move(unit, {-1, 0}, grass_map())
    end

    test "returns error when target tile is impassable" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert {:error, :impassable} = Unit.move(unit, {1, 0}, blocked_map())
    end
  end

  describe "attack/2" do
    test "reduces defender hp by attacker attack value" do
      attacker = Unit.new(1, :footman, :player1, {0, 0})
      defender = Unit.new(2, :grunt, :player2, {1, 0})
      result = Unit.attack(attacker, defender)
      assert result.hp == defender.hp - attacker.attack
    end

    test "does not reduce defender hp below zero" do
      attacker = %{Unit.new(1, :footman, :player1, {0, 0}) | attack: 1000}
      defender = Unit.new(2, :grunt, :player2, {1, 0})
      result = Unit.attack(attacker, defender)
      assert result.hp == 0
    end
  end

  describe "adjacent_to?/2" do
    test "returns true for horizontally adjacent position" do
      unit = Unit.new(1, :footman, :player1, {2, 2})
      assert Unit.adjacent_to?(unit, {3, 2})
      assert Unit.adjacent_to?(unit, {1, 2})
    end

    test "returns true for vertically adjacent position" do
      unit = Unit.new(1, :footman, :player1, {2, 2})
      assert Unit.adjacent_to?(unit, {2, 3})
      assert Unit.adjacent_to?(unit, {2, 1})
    end

    test "returns false for the unit's own position" do
      unit = Unit.new(1, :footman, :player1, {2, 2})
      refute Unit.adjacent_to?(unit, {2, 2})
    end

    test "returns false for diagonal position" do
      unit = Unit.new(1, :footman, :player1, {2, 2})
      refute Unit.adjacent_to?(unit, {3, 3})
    end
  end

  describe "harvest_amount/1" do
    test "workers return non-zero harvest" do
      {g, l} = Unit.harvest_amount(:peasant)
      assert g > 0 or l > 0
    end

    test "combat units return zero harvest" do
      assert {0, 0} = Unit.harvest_amount(:footman)
      assert {0, 0} = Unit.harvest_amount(:grunt)
    end
  end
end
