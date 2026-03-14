defmodule VibeCraft.Assets.Sprites do
  @moduledoc """
  Built-in original sprites shipped with VibeCraft.

  These serve as functional defaults and as living examples for the asset
  pipeline.  All pixel art here is original IP.
  """

  alias VibeCraft.Assets.Sprite

  # Compact pixel-art notation used below:
  #   K = black opaque  (0, 0, 0, 255)   — outline
  #   W = white opaque  (255, 255, 255, 255) — fill
  #   . = transparent   (0, 0, 0, 0)

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
    pixels =
      @cursor_art
      |> String.split("\n", trim: true)
      |> Enum.flat_map(fn row ->
        row
        |> String.trim()
        |> String.graphemes()
        |> Enum.map(&char_to_rgba/1)
      end)
      |> :erlang.iolist_to_binary()

    Sprite.new(16, 16, pixels)
  end

  @spec char_to_rgba(String.t()) :: binary()
  defp char_to_rgba("K"), do: <<0, 0, 0, 255>>
  defp char_to_rgba("W"), do: <<255, 255, 255, 255>>
  defp char_to_rgba("."), do: <<0, 0, 0, 0>>
end
