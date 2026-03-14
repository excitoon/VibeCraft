defmodule VibeCraft.Map.LoaderTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Map.{Loader, Map, Tile}

  describe "parse/1" do
    test "parses a simple 3×2 map string" do
      input = "GGG\nGTG\n"
      assert {:ok, %Map{width: 3, height: 2}} = Loader.parse(input)
    end

    test "ignores comment lines" do
      input = "# comment\nGGG\n# another\nGGG\n"
      assert {:ok, %Map{width: 3, height: 2}} = Loader.parse(input)
    end

    test "ignores blank lines" do
      input = "GGG\n\nGGG\n"
      assert {:ok, %Map{width: 3, height: 2}} = Loader.parse(input)
    end

    test "parses all supported tile characters" do
      input = "GWTRMG\n"
      assert {:ok, %Map{width: 6, height: 1} = map} = Loader.parse(input)
      assert %Tile{type: :grass} = Map.tile_at(map, {0, 0})
      assert %Tile{type: :water} = Map.tile_at(map, {1, 0})
      assert %Tile{type: :trees} = Map.tile_at(map, {2, 0})
      assert %Tile{type: :rock} = Map.tile_at(map, {3, 0})
      assert %Tile{type: :gold_mine} = Map.tile_at(map, {4, 0})
      assert %Tile{type: :grass} = Map.tile_at(map, {5, 0})
    end

    test "returns error for empty input" do
      assert {:error, :empty_map} = Loader.parse("")
    end

    test "returns error for inconsistent row widths" do
      assert {:error, :inconsistent_row_widths} = Loader.parse("GGG\nGG\n")
    end

    test "returns error for unknown tile character" do
      assert {:error, {:unknown_tile_char, "X"}} = Loader.parse("GXG\n")
    end
  end

  describe "load/1" do
    test "loads the bundled skirmish.map asset" do
      path = Application.app_dir(:vibe_craft, "priv/maps/skirmish.map")
      assert {:ok, %Map{width: 24, height: 16}} = Loader.load(path)
    end

    test "returns error when file does not exist" do
      assert {:error, :enoent} = Loader.load("/nonexistent/skirmish.map")
    end
  end
end
