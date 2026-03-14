defmodule VibeCraft.GameTest do
  use ExUnit.Case, async: true

  alias VibeCraft.{Building, Game, Resources, Unit}
  alias VibeCraft.Map.{Map, Tile}

  # 5×5 all-grass map.
  defp grass_map do
    rows = for _ <- 0..4, do: for(_ <- 0..4, do: Tile.new(:grass))
    Map.new(rows)
  end

  describe "new/1" do
    test "starts with empty units, buildings and default resources" do
      game = Game.new(grass_map())
      assert game.units == %{}
      assert game.buildings == %{}
      assert game.tick == 0
      assert game.status == :ongoing
      assert game.resources[:player1].gold == 500
      assert game.resources[:player2].gold == 500
    end
  end

  describe "add_unit/4" do
    test "adds a unit with a unique id" do
      game = Game.new(grass_map())
      {game, unit} = Game.add_unit(game, :footman, :player1, {1, 1})
      assert is_integer(unit.id)
      assert Map.has_key?(game.units, unit.id)
    end

    test "each added unit gets a distinct id" do
      game = Game.new(grass_map())
      {game, u1} = Game.add_unit(game, :footman, :player1, {0, 0})
      {_game, u2} = Game.add_unit(game, :grunt, :player2, {4, 4})
      assert u1.id != u2.id
    end
  end

  describe "add_building/4" do
    test "adds a building with a unique id" do
      game = Game.new(grass_map())
      {game, building} = Game.add_building(game, :town_hall, :player1, {1, 1})
      assert is_integer(building.id)
      assert Map.has_key?(game.buildings, building.id)
    end
  end

  describe "move_unit/3" do
    test "moves unit to adjacent passable tile" do
      game = Game.new(grass_map())
      {game, unit} = Game.add_unit(game, :footman, :player1, {0, 0})
      assert {:ok, updated} = Game.move_unit(game, unit, {1, 0})
      assert updated.units[unit.id].position == {1, 0}
    end

    test "returns error for impassable target" do
      rows = [
        [Tile.new(:grass), Tile.new(:water)],
        [Tile.new(:grass), Tile.new(:grass)]
      ]

      game = Game.new(Map.new(rows))
      {game, unit} = Game.add_unit(game, :footman, :player1, {0, 0})
      assert {:error, :impassable} = Game.move_unit(game, unit, {1, 0})
    end
  end

  describe "attack/3" do
    test "reduces defender hp" do
      game = Game.new(grass_map())
      {game, attacker} = Game.add_unit(game, :footman, :player1, {0, 0})
      {game, defender} = Game.add_unit(game, :grunt, :player2, {1, 0})
      updated = Game.attack(game, attacker, defender)
      assert updated.units[defender.id].hp < defender.hp
    end

    test "removes defender when hp reaches zero" do
      game = Game.new(grass_map())
      {game, attacker} = Game.add_unit(game, :footman, :player1, {0, 0})
      {game, defender} = Game.add_unit(game, :grunt, :player2, {1, 0})
      weak_defender = %{defender | hp: 1}
      game = %{game | units: Map.put(game.units, defender.id, weak_defender)}
      updated = Game.attack(game, attacker, weak_defender)
      refute Map.has_key?(updated.units, defender.id)
    end
  end

  describe "train_unit/3" do
    test "enqueues training and deducts resources" do
      game = Game.new(grass_map())
      {game, barracks} = Game.add_building(game, :barracks, :player1, {2, 2})
      assert {:ok, updated} = Game.train_unit(game, barracks, :footman)
      assert length(updated.buildings[barracks.id].training_queue) == 1
      assert updated.resources[:player1].gold < 500
    end

    test "returns error when building cannot train the unit type" do
      game = Game.new(grass_map())
      {game, town_hall} = Game.add_building(game, :town_hall, :player1, {2, 2})
      assert {:error, :cannot_train} = Game.train_unit(game, town_hall, :footman)
    end

    test "returns error when resources are insufficient" do
      game = Game.new(grass_map())
      game = %{game | resources: %{player1: Resources.new(0, 0), player2: Resources.new()}}
      {game, barracks} = Game.add_building(game, :barracks, :player1, {2, 2})
      assert {:error, :insufficient_resources} = Game.train_unit(game, barracks, :footman)
    end
  end

  describe "tick/1" do
    test "increments tick counter" do
      game = Game.new(grass_map())
      {game, _} = Game.add_unit(game, :footman, :player1, {2, 2})
      updated = Game.tick(game)
      assert updated.tick == 1
    end

    test "does not tick a decided game" do
      game = Game.new(grass_map())
      decided = %{game | status: {:victory, :player1}, tick: 5}
      assert Game.tick(decided).tick == 5
    end

    test "spawns unit when training completes" do
      game = Game.new(grass_map())
      # Place player1 unit so AI won't claim victory before training finishes.
      {game, _} = Game.add_unit(game, :footman, :player1, {4, 4})
      {game, barracks} = Game.add_building(game, :barracks, :player2, {2, 2})
      # Pre-load a near-done training entry.
      entry = %{unit_type: :grunt, ticks_remaining: 1}
      barracks = %{barracks | training_queue: [entry]}
      game = %{game | buildings: %{barracks.id => barracks}}
      before_count = map_size(game.units)
      updated = Game.tick(game)
      assert map_size(updated.units) > before_count
    end

    test "records player1 victory when player2 has no units or buildings" do
      game = Game.new(grass_map())
      {game, _} = Game.add_unit(game, :footman, :player1, {2, 2})
      game = Game.tick(game)
      assert game.status == {:victory, :player1}
    end
  end
end
