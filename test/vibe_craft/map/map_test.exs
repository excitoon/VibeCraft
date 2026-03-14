defmodule VibeCraft.Map.MapTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Map.{Map, Tile}

  # Build a simple 3×3 map: all grass except one water tile at {1, 1}.
  defp simple_map do
    rows = [
      [Tile.new(:grass), Tile.new(:grass), Tile.new(:grass)],
      [Tile.new(:grass), Tile.new(:water), Tile.new(:grass)],
      [Tile.new(:grass), Tile.new(:grass), Tile.new(:grass)]
    ]

    Map.new(rows)
  end

  describe "new/1" do
    test "stores width and height from rows" do
      map = simple_map()
      assert map.width == 3
      assert map.height == 3
    end

    test "all tiles start as :hidden in the fog" do
      map = simple_map()

      for r <- 0..2, c <- 0..2 do
        assert Map.fog_at(map, {c, r}) == :hidden
      end
    end

    test "tile_at returns correct tile" do
      map = simple_map()
      assert %Tile{type: :water} = Map.tile_at(map, {1, 1})
      assert %Tile{type: :grass} = Map.tile_at(map, {0, 0})
    end

    test "tile_at returns nil for out-of-bounds position" do
      map = simple_map()
      assert Map.tile_at(map, {10, 10}) == nil
    end
  end

  describe "reveal/3" do
    test "tiles within radius become :visible" do
      map = simple_map()
      map = Map.reveal(map, [{1, 1}], 1)

      assert Map.fog_at(map, {1, 1}) == :visible
      assert Map.fog_at(map, {0, 1}) == :visible
      assert Map.fog_at(map, {2, 1}) == :visible
    end

    test "tiles outside radius remain :hidden" do
      map = simple_map()
      map = Map.reveal(map, [{0, 0}], 1)

      assert Map.fog_at(map, {2, 2}) == :hidden
    end

    test "previously visible tiles become :explored on next reveal" do
      map = simple_map()
      map = Map.reveal(map, [{0, 0}], 1)
      assert Map.fog_at(map, {0, 0}) == :visible

      map = Map.reveal(map, [{2, 2}], 1)
      assert Map.fog_at(map, {0, 0}) == :explored
    end
  end

  describe "adjacent/2" do
    test "centre tile has four neighbours" do
      map = simple_map()
      adj = Map.adjacent(map, {1, 1})
      assert length(adj) == 4
      assert {0, 1} in adj
      assert {2, 1} in adj
      assert {1, 0} in adj
      assert {1, 2} in adj
    end

    test "corner tile has two neighbours" do
      map = simple_map()
      adj = Map.adjacent(map, {0, 0})
      assert length(adj) == 2
      assert {1, 0} in adj
      assert {0, 1} in adj
    end

    test "edge tile has three neighbours" do
      map = simple_map()
      adj = Map.adjacent(map, {1, 0})
      assert length(adj) == 3
    end
  end

  describe "in_bounds?/2" do
    test "valid position is in bounds" do
      map = simple_map()
      assert Map.in_bounds?(map, {0, 0})
      assert Map.in_bounds?(map, {2, 2})
    end

    test "negative position is out of bounds" do
      map = simple_map()
      refute Map.in_bounds?(map, {-1, 0})
    end

    test "position beyond dimensions is out of bounds" do
      map = simple_map()
      refute Map.in_bounds?(map, {3, 0})
      refute Map.in_bounds?(map, {0, 3})
    end
  end

  describe "put_tile/3" do
    test "replaces the tile at the given position" do
      map = simple_map()
      new_tile = Tile.new(:rock)
      updated = Map.put_tile(map, {0, 0}, new_tile)
      assert %Tile{type: :rock} = Map.tile_at(updated, {0, 0})
    end
  end
end
