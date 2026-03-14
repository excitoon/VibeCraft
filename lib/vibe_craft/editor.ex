defmodule VibeCraft.Editor do
  @moduledoc """
  Custom map and scenario editor for Phase 3.

  An `Editor` holds a mutable scenario definition: a tile-based map plus
  starting placements for units, buildings, and per-player resources.  The
  editor produces a `scenario()` map that can initialise a `VibeCraft.Game`.

  ## Usage

      editor = Editor.new("My Scenario", 16, 16)
      editor = Editor.set_tile(editor, {3, 4}, Tile.new(:water))
      editor = Editor.set_starting_unit(editor, :player1, :paladin, {0, 0})
      editor = Editor.set_starting_resources(editor, :player1, 1000, 500)
      scenario = Editor.export(editor)
  """

  alias VibeCraft.Building
  alias VibeCraft.Map.Map, as: GameMap
  alias VibeCraft.Map.Tile
  alias VibeCraft.Unit

  @type player :: Unit.player()
  @type position :: GameMap.position()

  @type starting_unit :: %{player: player(), type: Unit.unit_type(), position: position()}

  @type starting_building :: %{
          player: player(),
          type: Building.building_type(),
          position: position()
        }

  @type starting_resources :: %{gold: non_neg_integer(), lumber: non_neg_integer()}

  @type scenario :: %{
          name: String.t(),
          map: GameMap.t(),
          starting_units: [starting_unit()],
          starting_buildings: [starting_building()],
          starting_resources: %{player() => starting_resources()}
        }

  @type t :: %__MODULE__{
          name: String.t(),
          map: GameMap.t(),
          starting_units: [starting_unit()],
          starting_buildings: [starting_building()],
          starting_resources: %{player() => starting_resources()}
        }

  @enforce_keys [:name, :map]
  defstruct [
    :name,
    :map,
    starting_units: [],
    starting_buildings: [],
    starting_resources: %{}
  ]

  @doc """
  Create a new blank scenario with a flat `:grass` map of `width × height` tiles.
  """
  @spec new(String.t(), pos_integer(), pos_integer()) :: t()
  def new(name, width, height) do
    rows =
      for _r <- 0..(height - 1) do
        for _c <- 0..(width - 1), do: Tile.new(:grass)
      end

    %__MODULE__{name: name, map: GameMap.new(rows)}
  end

  @doc "Replace the tile at `pos` with `tile`."
  @spec set_tile(t(), position(), Tile.t()) :: t()
  def set_tile(%__MODULE__{map: map} = editor, pos, tile) do
    %{editor | map: GameMap.put_tile(map, pos, tile)}
  end

  @doc "Add a starting unit of `type` for `player` at `position`."
  @spec set_starting_unit(t(), player(), Unit.unit_type(), position()) :: t()
  def set_starting_unit(editor, player, type, position) do
    entry = %{player: player, type: type, position: position}
    %{editor | starting_units: [entry | editor.starting_units]}
  end

  @doc "Add a starting building of `type` for `player` at `position`."
  @spec set_starting_building(t(), player(), Building.building_type(), position()) :: t()
  def set_starting_building(editor, player, type, position) do
    entry = %{player: player, type: type, position: position}
    %{editor | starting_buildings: [entry | editor.starting_buildings]}
  end

  @doc "Set the starting gold and lumber for `player`."
  @spec set_starting_resources(t(), player(), non_neg_integer(), non_neg_integer()) :: t()
  def set_starting_resources(editor, player, gold, lumber) do
    resources = Map.put(editor.starting_resources, player, %{gold: gold, lumber: lumber})
    %{editor | starting_resources: resources}
  end

  @doc """
  Export the current editor state as a `scenario()` map.

  Starting unit and building lists are returned in declaration order.
  """
  @spec export(t()) :: scenario()
  def export(%__MODULE__{} = editor) do
    %{
      name: editor.name,
      map: editor.map,
      starting_units: Enum.reverse(editor.starting_units),
      starting_buildings: Enum.reverse(editor.starting_buildings),
      starting_resources: editor.starting_resources
    }
  end
end
