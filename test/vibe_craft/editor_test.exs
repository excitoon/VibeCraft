defmodule VibeCraft.EditorTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Editor
  alias VibeCraft.Map.Map, as: GameMap
  alias VibeCraft.Map.Tile

  defp small, do: Editor.new("Test", 4, 4)

  describe "new/3" do
    test "creates an editor with the given name and dimensions" do
      editor = small()
      assert editor.name == "Test"
      assert editor.map.width == 4
      assert editor.map.height == 4
    end

    test "all tiles default to :grass" do
      editor = small()

      for c <- 0..3, r <- 0..3 do
        tile = GameMap.tile_at(editor.map, {c, r})
        assert tile.type == :grass
      end
    end

    test "starting lists are empty" do
      editor = small()
      assert editor.starting_units == []
      assert editor.starting_buildings == []
      assert editor.starting_resources == %{}
    end
  end

  describe "set_tile/3" do
    test "replaces a tile in the map" do
      editor = Editor.set_tile(small(), {1, 2}, Tile.new(:water))
      tile = GameMap.tile_at(editor.map, {1, 2})
      assert tile.type == :water
    end
  end

  describe "set_starting_unit/4" do
    test "records a starting unit" do
      editor = Editor.set_starting_unit(small(), :player1, :footman, {0, 0})
      assert length(editor.starting_units) == 1
      [entry] = editor.starting_units
      assert entry.player == :player1
      assert entry.type == :footman
      assert entry.position == {0, 0}
    end

    test "accumulates multiple units" do
      editor =
        small()
        |> Editor.set_starting_unit(:player1, :footman, {0, 0})
        |> Editor.set_starting_unit(:player2, :grunt, {3, 3})

      assert length(editor.starting_units) == 2
    end
  end

  describe "set_starting_building/4" do
    test "records a starting building" do
      editor = Editor.set_starting_building(small(), :player1, :town_hall, {0, 0})
      assert length(editor.starting_buildings) == 1
    end
  end

  describe "set_starting_resources/4" do
    test "records gold and lumber for a player" do
      editor = Editor.set_starting_resources(small(), :player1, 500, 200)
      assert editor.starting_resources[:player1] == %{gold: 500, lumber: 200}
    end

    test "can set resources for both players independently" do
      editor =
        small()
        |> Editor.set_starting_resources(:player1, 500, 200)
        |> Editor.set_starting_resources(:player2, 1_000, 400)

      assert editor.starting_resources[:player1].gold == 500
      assert editor.starting_resources[:player2].gold == 1_000
    end
  end

  describe "export/1" do
    test "exported scenario contains all editor fields" do
      scenario =
        small()
        |> Editor.set_starting_unit(:player1, :footman, {0, 0})
        |> Editor.set_starting_building(:player1, :town_hall, {1, 0})
        |> Editor.set_starting_resources(:player1, 500, 200)
        |> Editor.export()

      assert scenario.name == "Test"
      assert length(scenario.starting_units) == 1
      assert length(scenario.starting_buildings) == 1
      assert scenario.starting_resources[:player1].gold == 500
    end

    test "exported units are in declaration order" do
      scenario =
        small()
        |> Editor.set_starting_unit(:player1, :footman, {0, 0})
        |> Editor.set_starting_unit(:player1, :peasant, {1, 0})
        |> Editor.export()

      types = Enum.map(scenario.starting_units, & &1.type)
      assert types == [:footman, :peasant]
    end
  end
end
