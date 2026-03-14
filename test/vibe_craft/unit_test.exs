defmodule VibeCraft.UnitTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Map.{Map, Tile}
  alias VibeCraft.Unit

  # A 3×3 all-grass map for movement tests.
  defp grass_map do
    rows = for _ <- 0..2, do: for(_ <- 0..2, do: Tile.new(:grass))
    Map.new(rows)
  end

  # A 3×3 all-water map for naval movement tests.
  defp water_map do
    rows = for _ <- 0..2, do: for(_ <- 0..2, do: Tile.new(:water))
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
      assert unit.layer == :ground
    end

    test "creates a peasant with correct stats" do
      unit = Unit.new(1, :peasant, :player1, {0, 0})
      assert unit.hp == 30
      assert unit.attack == 3
      assert unit.layer == :ground
    end

    test "creates a grunt with correct stats" do
      unit = Unit.new(1, :grunt, :player2, {0, 0})
      assert unit.hp == 60
      assert unit.attack == 8
      assert unit.layer == :ground
    end

    test "creates a peon with correct stats" do
      unit = Unit.new(1, :peon, :player2, {0, 0})
      assert unit.hp == 30
      assert unit.attack == 3
      assert unit.layer == :ground
    end

    test "creates a destroyer with naval layer" do
      unit = Unit.new(1, :destroyer, :player1, {0, 0})
      assert unit.hp == 100
      assert unit.attack == 10
      assert unit.layer == :naval
    end

    test "creates a battleship with naval layer" do
      unit = Unit.new(1, :battleship, :player1, {0, 0})
      assert unit.hp == 150
      assert unit.attack == 15
      assert unit.layer == :naval
    end

    test "creates an oil_tanker with naval layer" do
      unit = Unit.new(1, :oil_tanker, :player1, {0, 0})
      assert unit.layer == :naval
    end

    test "creates a transport with naval layer" do
      unit = Unit.new(1, :transport, :player1, {0, 0})
      assert unit.layer == :naval
    end

    test "creates a gryphon with air layer" do
      unit = Unit.new(1, :gryphon, :player1, {0, 0})
      assert unit.hp == 80
      assert unit.attack == 12
      assert unit.layer == :air
    end

    test "creates a dragon with air layer" do
      unit = Unit.new(1, :dragon, :player2, {0, 0})
      assert unit.hp == 120
      assert unit.attack == 16
      assert unit.layer == :air
    end

    test "creates a paladin with mana pool" do
      unit = Unit.new(1, :paladin, :player1, {0, 0})
      assert unit.hp == 150
      assert unit.max_mana == 200
      assert unit.mana == 200
      assert unit.layer == :ground
    end

    test "creates a death_knight with mana pool" do
      unit = Unit.new(1, :death_knight, :player2, {0, 0})
      assert unit.hp == 150
      assert unit.max_mana == 200
      assert unit.mana == 200
      assert unit.layer == :ground
    end

    test "non-hero units start with zero mana" do
      for type <- [:footman, :peasant, :grunt, :peon, :destroyer, :gryphon] do
        unit = Unit.new(1, type, :player1, {0, 0})
        assert unit.mana == 0
        assert unit.max_mana == 0
      end
    end

    test "all units start at level 1 with 0 xp" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert unit.level == 1
      assert unit.xp == 0
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

  describe "move/3 — ground units" do
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

    test "returns error when target tile is impassable (water)" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert {:error, :impassable} = Unit.move(unit, {1, 0}, blocked_map())
    end
  end

  describe "move/3 — naval units" do
    test "moves to an adjacent water tile" do
      unit = Unit.new(1, :destroyer, :player1, {0, 0})
      assert {:ok, moved} = Unit.move(unit, {1, 0}, water_map())
      assert moved.position == {1, 0}
    end

    test "returns error when target is grass (not naval-passable)" do
      unit = Unit.new(1, :destroyer, :player1, {0, 0})
      assert {:error, :impassable} = Unit.move(unit, {1, 0}, grass_map())
    end
  end

  describe "move/3 — air units" do
    test "air unit moves over grass" do
      unit = Unit.new(1, :gryphon, :player1, {0, 0})
      assert {:ok, moved} = Unit.move(unit, {1, 0}, grass_map())
      assert moved.position == {1, 0}
    end

    test "air unit moves over water" do
      unit = Unit.new(1, :gryphon, :player1, {0, 0})
      assert {:ok, moved} = Unit.move(unit, {1, 0}, water_map())
      assert moved.position == {1, 0}
    end

    test "air unit moves over blocked tile" do
      unit = Unit.new(1, :dragon, :player2, {0, 0})
      # The blocked_map has water at {1,0}, air units can cross it.
      assert {:ok, _} = Unit.move(unit, {1, 0}, blocked_map())
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

  describe "spend_mana/2" do
    test "deducts mana when affordable" do
      unit = Unit.new(1, :paladin, :player1, {0, 0})
      assert {:ok, updated} = Unit.spend_mana(unit, 65)
      assert updated.mana == unit.mana - 65
    end

    test "returns error when not enough mana" do
      unit = %{Unit.new(1, :paladin, :player1, {0, 0}) | mana: 10}
      assert {:error, :insufficient_mana} = Unit.spend_mana(unit, 65)
    end
  end

  describe "tick_mana/1" do
    test "regenerates 1 mana for units with a mana pool" do
      unit = %{Unit.new(1, :paladin, :player1, {0, 0}) | mana: 100}
      updated = Unit.tick_mana(unit)
      assert updated.mana == 101
    end

    test "does not exceed max_mana" do
      unit = Unit.new(1, :paladin, :player1, {0, 0})
      # mana == max_mana already
      updated = Unit.tick_mana(unit)
      assert updated.mana == unit.max_mana
    end

    test "no-ops for units without a mana pool" do
      unit = Unit.new(1, :footman, :player1, {0, 0})
      assert Unit.tick_mana(unit) == unit
    end
  end

  describe "add_xp/2" do
    test "adds xp to a unit" do
      unit = Unit.new(1, :paladin, :player1, {0, 0})
      updated = Unit.add_xp(unit, 150)
      assert updated.xp == 150
    end
  end
end
