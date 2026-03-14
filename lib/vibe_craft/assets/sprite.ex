defmodule VibeCraft.Assets.Sprite do
  @moduledoc """
  Sprite data: raw RGBA pixel bytes plus width and height.

  `pixels` is a binary of exactly `width * height * 4` bytes in row-major
  order; each pixel is four consecutive bytes `<<R, G, B, A>>`.
  """

  @enforce_keys [:width, :height, :pixels]
  defstruct [:width, :height, :pixels]

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          pixels: binary()
        }

  @doc """
  Create a new sprite from raw RGBA pixel data.

  Raises `ArgumentError` when `pixels` length does not equal
  `width * height * 4`.
  """
  @spec new(pos_integer(), pos_integer(), binary()) :: t()
  def new(width, height, pixels)
      when is_integer(width) and width > 0 and
             is_integer(height) and height > 0 and
             is_binary(pixels) do
    expected = width * height * 4

    if byte_size(pixels) != expected do
      raise ArgumentError,
            "expected #{expected} bytes for #{width}×#{height} RGBA sprite, " <>
              "got #{byte_size(pixels)}"
    end

    %__MODULE__{width: width, height: height, pixels: pixels}
  end
end
