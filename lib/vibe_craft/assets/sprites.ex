defmodule VibeCraft.Assets.Sprites do
  @moduledoc """
  Built-in original sprites shipped with VibeCraft.

  These serve as functional defaults and as living examples for the asset
  pipeline.  All pixel art here is original IP.

  The canonical source artwork for every terrain tile is an SVG file stored in
  `priv/art/` (e.g. `priv/art/terrain_grass.svg`).  The ASCII grids below were
  derived from those SVGs and must be kept in sync with them.

  ## Pixel-art character palette (used across all sprites)

  | Char | Color                    | RGBA              |
  |------|--------------------------|-------------------|
  | `.`  | transparent              | (0,0,0,0)         |
  | `K`  | black outline            | (0,0,0,255)       |
  | `W`  | white                    | (255,255,255,255) |
  | `G`  | grass green              | (60,179,67,255)   |
  | `g`  | dark grass               | (40,120,45,255)   |
  | `B`  | water blue               | (30,144,255,255)  |
  | `b`  | dark water               | (20,100,180,255)  |
  | `T`  | tree canopy              | (34,139,34,255)   |
  | `t`  | tree trunk / bark        | (101,67,33,255)   |
  | `R`  | rock grey                | (120,120,120,255) |
  | `r`  | dark rock                | (80,80,80,255)    |
  | `Y`  | gold yellow              | (220,180,0,255)   |
  | `y`  | dark gold                | (160,130,0,255)   |
  | `S`  | skin tone                | (255,200,140,255) |
  | `A`  | blue armour              | (70,130,180,255)  |
  | `a`  | dark blue armour         | (47,90,130,255)   |
  | `O`  | orc skin green           | (80,160,50,255)   |
  | `o`  | dark orc skin            | (55,110,35,255)   |
  | `N`  | brown leather / wood     | (139,90,43,255)   |
  | `n`  | dark brown               | (90,55,20,255)    |
  | `E`  | stone beige              | (200,180,140,255) |
  | `e`  | dark stone               | (150,130,100,255) |
  | `D`  | roof red-brown           | (160,60,30,255)   |
  | `d`  | dark roof                | (110,40,20,255)   |
  """

  alias VibeCraft.Assets.Sprite

  @dialyzer {:nowarn_function, [render_art: 3, char_to_rgba: 1]}

  # ── Cursor ────────────────────────────────────────────────────────────────

  @cursor_art ~S"""
  K...............
  KWK.............
  KWWK............
  KWWWK...........
  KWWWWK..........
  KWWWWWK.........
  KWWWWWWK........
  KWWWWWWWK.......
  KWWWWWWKK.......
  KWWKWWK.........
  KWK.KWWK........
  KK...KWWK.......
  ......KWWK......
  .......KWK......
  ........K.......
  ................
  """

  @doc """
  A 16×16 pixel-art cursor sprite in RGBA format.

  The cursor is an original VibeCraft design — a simple arrow with a
  black outline and white fill for readability at small sizes.
  """
  @spec cursor() :: Sprite.t()
  def cursor do
    render_art(@cursor_art, 16, 16)
  end

  # ── Terrain tiles (16×16) ─────────────────────────────────────────────────

  @terrain_grass_art ~S"""
  GGgGGGGgGGgGGGGG
  GGGGGGGGGgGGGGGG
  gGGGGGgGGGGGGGGG
  GGGGGgGGGGGGgGGG
  GGgGGGGGGGGGGGGG
  GGGGGGGGgGGGGGgG
  GGGGgGGGGGGGGGGG
  GgGGGGGGGGgGGGGG
  GGGGGGgGGGGGGgGG
  GGGGGGGGGgGGGGGG
  gGGGgGGGGGGGGGGG
  GGGGGGGGGgGGGGGG
  GGGGGGgGGGGGGGGG
  GgGGGGGGGGGGGGgG
  GGGGGGGGGGGGgGGG
  GGGGgGGGGGGGGGGG
  """

  @doc """
  A 16×16 grass terrain tile.

  Used as the base passable ground surface.  SVG source: `priv/art/terrain_grass.svg`.
  """
  @spec terrain_grass() :: Sprite.t()
  def terrain_grass do
    render_art(@terrain_grass_art, 16, 16)
  end

  @terrain_water_art ~S"""
  BBbBBBBbBBbBBBBB
  BBBBBbBBBBBBBBBB
  bBBBBBBbBBBBbBBB
  BBBBBBBBBbBBBBBB
  BBbBBBBBBBBBBBBb
  BBBBBBBBbBBBBBBB
  BBBBbBBBBBBBBBBB
  BbBBBBBBBBbBBBBB
  BBBBBBbBBBBBBbBB
  BBBBBBBBBbBBBBBB
  bBBBbBBBBBBBBBBB
  BBBBBBBBBbBBBBBB
  BBBBBBbBBBBBBBBB
  BbBBBBBBBBBBBBbB
  BBBBBBBBBBBBbBBB
  BBBBbBBBBBBBBBBB
  """

  @doc """
  A 16×16 water terrain tile.

  Impassable for ground units.  SVG source: `priv/art/terrain_water.svg`.
  """
  @spec terrain_water() :: Sprite.t()
  def terrain_water do
    render_art(@terrain_water_art, 16, 16)
  end

  @terrain_trees_art ~S"""
  ....TTTT........
  ...TTTTTT.......
  ..TTTTTTTT......
  ..TTTTTTTT......
  .TTTTTTTTTT.....
  .TTTTTTTTTT.....
  TTTTTTTTTTTT....
  TTTTTTTTTTTT....
  .TTTTTTTTTT.....
  ..TTTTTTTT......
  ....tttt........
  ....tttt........
  ....tttt........
  ....tttt........
  ................
  ................
  """

  @doc """
  A 16×16 trees terrain tile.

  Impassable; worker units can harvest lumber from adjacent tree tiles.
  SVG source: `priv/art/terrain_trees.svg`.
  """
  @spec terrain_trees() :: Sprite.t()
  def terrain_trees do
    render_art(@terrain_trees_art, 16, 16)
  end

  @terrain_rock_art ~S"""
  RRrRRrRRRrRRRrRR
  RrRRRRrRRrRRRRrR
  rRRRrRRRrRRrRRRR
  RRRrRRrRRRRrRRrR
  RrRRRRRrRRRRRrRR
  RRrRRrRRrRRRRRrR
  rRRRrRRRRrRRrRRR
  RRRRRrRRrRRRrRRR
  RrRRrRRrRRrRRRRr
  RRRRrRRRrRRRrRRR
  rRRRRrRRRrRRRRRr
  RRrRRRrRRrRRrRRR
  RRRrRRrRRRrRRRrR
  rRRRRRrRRrRRRRRr
  RRrRRrRRRrRRrRRR
  RRRrRRRrRRRrRRRR
  """

  @doc """
  A 16×16 rock terrain tile.

  Impassable rocky ground.  SVG source: `priv/art/terrain_rock.svg`.
  """
  @spec terrain_rock() :: Sprite.t()
  def terrain_rock do
    render_art(@terrain_rock_art, 16, 16)
  end

  @terrain_gold_mine_art ~S"""
  ................
  ..KKKKKKKKKK....
  .KrrrrrrrrrK....
  .KrYYYYYYrrK....
  .KrYyYyYYrK.....
  .KrYYYYYrrK.....
  .KrYyYyYYrK.....
  .KrYYYYYrrK.....
  .KrrrrrrrK......
  .KKKKKKKK.......
  ...KKKKK........
  ..KrrrrrK.......
  ..KrrrrrK.......
  ..KKKKKKK.......
  ................
  ................
  """

  @doc """
  A 16×16 gold mine terrain tile.

  Impassable; worker units can harvest gold from adjacent gold mine tiles.
  SVG source: `priv/art/terrain_gold_mine.svg`.
  """
  @spec terrain_gold_mine() :: Sprite.t()
  def terrain_gold_mine do
    render_art(@terrain_gold_mine_art, 16, 16)
  end

  # ── Unit sprites (16×16) ─────────────────────────────────────────────────

  @unit_footman_art ~S"""
  ....KWWWK.......
  ....KSWSK.......
  ....KAAAK.......
  ...KKaAaKK......
  ..KAAaaaaAK.....
  ..KAAaWWaAK.....
  ...KAaaaaK......
  ....KWWWK.......
  ...KKWWKk.......
  ..KaKKKKaK......
  .KaaKKKKaaK.....
  .KaKKKKKKaK.....
  ..KKK..KKK......
  ...KK...KK......
  ................
  ................
  """

  @doc """
  A 16×16 footman (human melee fighter) sprite.

  Footmen are the basic human combat unit: blue-armoured warriors who
  defend settlements and press the attack.
  """
  @spec unit_footman() :: Sprite.t()
  def unit_footman do
    render_art(@unit_footman_art, 16, 16)
  end

  @unit_peasant_art ~S"""
  ....KWWWK.......
  ....KSWSK.......
  ....KNNK........
  ...KNNNnK.......
  ..KNNKKNnK......
  ..KNNKKNnK......
  ...KNNNnK.......
  ....KNNK........
  ...KKNNKk.......
  ..KnKKKKnK......
  .KnnKKKKnnK.....
  .KnKKKKKKnK.....
  ..KKK..KKK......
  ...KK...KK......
  ................
  ................
  """

  @doc """
  A 16×16 peasant (human worker) sprite.

  Peasants gather Gold and Lumber and construct buildings.
  """
  @spec unit_peasant() :: Sprite.t()
  def unit_peasant do
    render_art(@unit_peasant_art, 16, 16)
  end

  # ── Building sprites (16×16) ──────────────────────────────────────────────

  @building_town_hall_art ~S"""
  ....KKKKKKKK....
  ...KEeEeEeEK....
  ...KEeEeEeEK....
  ..KDdDdddDdDK...
  .KDdddddddddDK..
  .KEEEEEEEEEEEK..
  .KEeEeEeEeEeEK..
  .KEeEeEeEeEeEK..
  .KEEEEEEEEEEEK..
  .KEeEeEeEeEeEK..
  .KEEE.KKK.EEEK..
  .KEEE.KNK.EEEK..
  .KEEE.KNK.EEEK..
  .KEEEKKNKKEEKK..
  .KKKKKKKKKKKK...
  ................
  """

  @doc """
  A 16×16 town hall building sprite.

  The town hall is the primary structure: it trains workers and acts as a
  resource drop-off point.
  """
  @spec building_town_hall() :: Sprite.t()
  def building_town_hall do
    render_art(@building_town_hall_art, 16, 16)
  end

  @building_barracks_art ~S"""
  ...KKKKKKKKKK...
  ..KDdDdDdDdDDK..
  ..KDdDdDdDdDDK..
  .KDDDdddddDDDDK.
  .KEEEEEEEEEEeEK.
  .KEeEeEeEeEeEeK.
  .KEEEEEEEEEEeEK.
  .KEeEeEeEeEeEeK.
  .KEEEEEEEEEEEEK.
  .KE.KKK.KKK.EEK.
  .KE.KNK.KNK.EEK.
  .KE.KNK.KNK.EEK.
  .KEEKNKKKNKKEEK.
  .KKKKKKKKKKKKK..
  ................
  ................
  """

  @doc """
  A 16×16 barracks building sprite.

  The barracks trains combat units (footmen for humans, grunts for orcs).
  """
  @spec building_barracks() :: Sprite.t()
  def building_barracks do
    render_art(@building_barracks_art, 16, 16)
  end

  # ── Private helpers ────────────────────────────────────────────────────────

  @spec render_art(String.t(), pos_integer(), pos_integer()) :: Sprite.t()
  defp render_art(art, width, height) do
    pixels =
      art
      |> String.split("\n", trim: true)
      |> Enum.flat_map(fn row ->
        row
        |> String.trim()
        |> String.graphemes()
        |> Enum.map(&char_to_rgba/1)
      end)
      |> :erlang.iolist_to_binary()

    Sprite.new(width, height, pixels)
  end

  @spec char_to_rgba(String.t()) :: binary()
  defp char_to_rgba("."), do: <<0, 0, 0, 0>>
  defp char_to_rgba("K"), do: <<0, 0, 0, 255>>
  defp char_to_rgba("W"), do: <<255, 255, 255, 255>>
  defp char_to_rgba("G"), do: <<60, 179, 67, 255>>
  defp char_to_rgba("g"), do: <<40, 120, 45, 255>>
  defp char_to_rgba("B"), do: <<30, 144, 255, 255>>
  defp char_to_rgba("b"), do: <<20, 100, 180, 255>>
  defp char_to_rgba("T"), do: <<34, 139, 34, 255>>
  defp char_to_rgba("t"), do: <<101, 67, 33, 255>>
  defp char_to_rgba("R"), do: <<120, 120, 120, 255>>
  defp char_to_rgba("r"), do: <<80, 80, 80, 255>>
  defp char_to_rgba("Y"), do: <<220, 180, 0, 255>>
  defp char_to_rgba("y"), do: <<160, 130, 0, 255>>
  defp char_to_rgba("S"), do: <<255, 200, 140, 255>>
  defp char_to_rgba("A"), do: <<70, 130, 180, 255>>
  defp char_to_rgba("a"), do: <<47, 90, 130, 255>>
  defp char_to_rgba("O"), do: <<80, 160, 50, 255>>
  defp char_to_rgba("o"), do: <<55, 110, 35, 255>>
  defp char_to_rgba("N"), do: <<139, 90, 43, 255>>
  defp char_to_rgba("n"), do: <<90, 55, 20, 255>>
  defp char_to_rgba("E"), do: <<200, 180, 140, 255>>
  defp char_to_rgba("e"), do: <<150, 130, 100, 255>>
  defp char_to_rgba("D"), do: <<160, 60, 30, 255>>
  defp char_to_rgba("d"), do: <<110, 40, 20, 255>>
  defp char_to_rgba("k"), do: <<30, 30, 30, 255>>
end
