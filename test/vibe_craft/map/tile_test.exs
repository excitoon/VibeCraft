defmodule VibeCraft.Map.TileTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Map.Tile

  describe "new/1" do
    test "creates a grass tile" do
      tile = Tile.new(:grass)
      assert tile.type == :grass
      assert tile.resource_amount == 0
    end

    test "creates a water tile" do
      tile = Tile.new(:water)
      assert tile.type == :water
      assert tile.resource_amount == 0
    end

    test "creates a trees tile with starting lumber" do
      tile = Tile.new(:trees)
      assert tile.type == :trees
      assert tile.resource_amount == 100
    end

    test "creates a rock tile" do
      tile = Tile.new(:rock)
      assert tile.type == :rock
      assert tile.resource_amount == 0
    end

    test "creates a gold mine tile with starting gold" do
      tile = Tile.new(:gold_mine)
      assert tile.type == :gold_mine
      assert tile.resource_amount == 5_000
    end
  end

  describe "passable?/1" do
    test "grass is passable" do
      assert Tile.passable?(Tile.new(:grass))
    end

    test "water is not passable" do
      refute Tile.passable?(Tile.new(:water))
    end

    test "trees is not passable" do
      refute Tile.passable?(Tile.new(:trees))
    end

    test "rock is not passable" do
      refute Tile.passable?(Tile.new(:rock))
    end

    test "gold mine is not passable" do
      refute Tile.passable?(Tile.new(:gold_mine))
    end
  end

  describe "has_lumber?/1" do
    test "trees tile has lumber" do
      assert Tile.has_lumber?(Tile.new(:trees))
    end

    test "other tiles do not have lumber" do
      for type <- [:grass, :water, :rock, :gold_mine] do
        refute Tile.has_lumber?(Tile.new(type)), "expected #{type} to have no lumber"
      end
    end
  end

  describe "has_gold?/1" do
    test "gold mine has gold" do
      assert Tile.has_gold?(Tile.new(:gold_mine))
    end

    test "other tiles do not have gold" do
      for type <- [:grass, :water, :trees, :rock] do
        refute Tile.has_gold?(Tile.new(type)), "expected #{type} to have no gold"
      end
    end
  end
end
