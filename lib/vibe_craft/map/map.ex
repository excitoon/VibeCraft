defmodule VibeCraft.Map.Map do
  @moduledoc """
  A tile-based game map with fog of war.

  The map is a 2-D grid of `VibeCraft.Map.Tile` structs.  Positions are
  `{col, row}` integer tuples with `{0, 0}` at the top-left.

  Fog-of-war states:
  - `:hidden`   — never seen; rendered as solid black.
  - `:explored` — seen before but not currently visible; rendered darkened.
  - `:visible`  — within sight of a friendly unit this tick.
  """

  alias VibeCraft.Map.Tile

  @type position :: {non_neg_integer(), non_neg_integer()}
  @type fog_state :: :hidden | :explored | :visible

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          tiles: %{position() => Tile.t()},
          fog: %{position() => fog_state()}
        }

  @enforce_keys [:width, :height, :tiles]
  defstruct [:width, :height, :tiles, fog: %{}]

  @doc """
  Create a new map from a 2-D list of tile rows.

  `rows` is a list of rows (outer) each containing a list of `Tile` structs
  (inner).  Map dimensions are inferred from the data.  All tiles start as
  `:hidden` in the fog of war.
  """
  @spec new([[Tile.t()]]) :: t()
  def new(rows) when is_list(rows) do
    height = length(rows)
    width = rows |> List.first([]) |> length()

    tiles =
      rows
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, r} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {tile, c} -> {{c, r}, tile} end)
      end)
      |> Map.new()

    fog =
      for r <- 0..(height - 1), c <- 0..(width - 1), into: %{} do
        {{c, r}, :hidden}
      end

    %__MODULE__{width: width, height: height, tiles: tiles, fog: fog}
  end

  @doc "Return the tile at `{col, row}`, or `nil` when out of bounds."
  @spec tile_at(t(), position()) :: Tile.t() | nil
  def tile_at(%__MODULE__{tiles: tiles}, pos), do: Map.get(tiles, pos)

  @doc "Return the fog-of-war state at `{col, row}`. Defaults to `:hidden`."
  @spec fog_at(t(), position()) :: fog_state()
  def fog_at(%__MODULE__{fog: fog}, pos), do: Map.get(fog, pos, :hidden)

  @doc """
  Reveal tiles within `radius` Manhattan steps of each position in `centers`.

  Previously `:visible` tiles not in the new sight area become `:explored`.
  """
  @spec reveal(t(), [position()], non_neg_integer()) :: t()
  def reveal(%__MODULE__{fog: fog, width: w, height: h} = map, centers, radius) do
    demoted =
      fog
      |> Enum.map(fn
        {pos, :visible} -> {pos, :explored}
        pair -> pair
      end)
      |> Map.new()

    visible_set =
      for {cx, cy} <- centers,
          dr <- -radius..radius,
          dc <- -radius..radius,
          abs(dr) + abs(dc) <= radius,
          r = cy + dr,
          c = cx + dc,
          r >= 0,
          r < h,
          c >= 0,
          c < w do
        {c, r}
      end

    new_fog =
      Enum.reduce(visible_set, demoted, fn pos, acc ->
        Map.put(acc, pos, :visible)
      end)

    %{map | fog: new_fog}
  end

  @doc """
  Return all positions 4-directionally adjacent to `pos` within map bounds.
  """
  @spec adjacent(t(), position()) :: [position()]
  def adjacent(%__MODULE__{width: w, height: h}, {c, r}) do
    [{c - 1, r}, {c + 1, r}, {c, r - 1}, {c, r + 1}]
    |> Enum.filter(fn {nc, nr} -> nc >= 0 and nc < w and nr >= 0 and nr < h end)
  end

  @doc "Return `true` when `pos` is within map bounds."
  @spec in_bounds?(t(), position()) :: boolean()
  def in_bounds?(%__MODULE__{width: w, height: h}, {c, r}) do
    c >= 0 and c < w and r >= 0 and r < h
  end

  @doc "Update the tile at `pos`, returning the modified map."
  @spec put_tile(t(), position(), Tile.t()) :: t()
  def put_tile(%__MODULE__{tiles: tiles} = map, pos, tile) do
    %{map | tiles: Map.put(tiles, pos, tile)}
  end
end
