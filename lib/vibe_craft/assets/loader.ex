defmodule VibeCraft.Assets.Loader do
  @moduledoc """
  File-based asset loader for VibeCraft sprites.

  Supports two formats:

  - **`.rgba`** — raw RGBA: a big-endian 32-bit unsigned `width`, a
    big-endian 32-bit unsigned `height`, followed by `width * height * 4`
    bytes of RGBA pixel data.

  - **`.tga`** — Truevision TGA, uncompressed true-color (image type 2),
    24-bit (BGR) or 32-bit (BGRA).  Both bottom-to-top and top-to-bottom
    vertical orientation are handled via the image-descriptor byte.

  Returns `{:ok, %VibeCraft.Assets.Sprite{}}` or `{:error, reason}`.
  """

  import Bitwise

  alias VibeCraft.Assets.Sprite

  @doc """
  Load a sprite from `path`.

  The file format is inferred from the file extension.
  """
  @spec load(Path.t()) :: {:ok, Sprite.t()} | {:error, term()}
  def load(path) do
    with {:ok, data} <- File.read(path) do
      case Path.extname(path) do
        ".rgba" -> decode_rgba(data)
        ".tga" -> decode_tga(data)
        ext -> {:error, {:unsupported_format, ext}}
      end
    end
  end

  # ── .rgba ──────────────────────────────────────────────────────────────────

  @spec decode_rgba(binary()) :: {:ok, Sprite.t()} | {:error, term()}
  defp decode_rgba(<<width::32-big-unsigned, height::32-big-unsigned, pixels::binary>>) do
    expected = width * height * 4

    if byte_size(pixels) == expected do
      {:ok, Sprite.new(width, height, pixels)}
    else
      {:error, {:invalid_rgba_data, expected: expected, got: byte_size(pixels)}}
    end
  end

  defp decode_rgba(_), do: {:error, :invalid_rgba_header}

  # ── .tga ───────────────────────────────────────────────────────────────────
  #
  # TGA header layout (18 bytes):
  #   0  id_length      (1 byte)
  #   1  color_map_type (1 byte)  — must be 0
  #   2  image_type     (1 byte)  — 2 = uncompressed true-color
  #   3  color_map_spec (5 bytes)
  #   8  x_origin       (2 bytes, little-endian)
  #  10  y_origin       (2 bytes, little-endian)
  #  12  width          (2 bytes, little-endian)
  #  14  height         (2 bytes, little-endian)
  #  16  bits_per_pixel (1 byte)  — 24 or 32
  #  17  image_desc     (1 byte)  — bit 5: 0 = bottom-to-top, 1 = top-to-bottom
  # 18+  optional image ID, then pixel data

  @spec decode_tga(binary()) :: {:ok, Sprite.t()} | {:error, term()}
  defp decode_tga(
         <<id_len::8, _color_map_type::8, 2::8, _color_map_spec::40, _x_origin::16-little,
           _y_origin::16-little, width::16-little-unsigned, height::16-little-unsigned, bpp::8,
           image_desc::8, rest::binary>>
       ) do
    # Skip optional image-ID field.
    <<_id::binary-size(id_len), pixels::binary>> = rest

    # Bit 5 of image_desc: 1 → top-to-bottom (no flip needed).
    top_to_bottom = (image_desc &&& 0x20) == 0x20

    with {:ok, sprite} <- decode_tga_pixels(pixels, width, height, bpp) do
      if top_to_bottom, do: {:ok, sprite}, else: {:ok, vflip(sprite)}
    end
  end

  defp decode_tga(_), do: {:error, :invalid_tga_header}

  @spec decode_tga_pixels(binary(), pos_integer(), pos_integer(), pos_integer()) ::
          {:ok, Sprite.t()} | {:error, term()}
  defp decode_tga_pixels(pixels, width, height, 24) do
    expected = width * height * 3

    if byte_size(pixels) >= expected do
      <<raw::binary-size(expected), _rest::binary>> = pixels
      {:ok, Sprite.new(width, height, bgr_to_rgba(raw))}
    else
      {:error, :truncated_tga_data}
    end
  end

  defp decode_tga_pixels(pixels, width, height, 32) do
    expected = width * height * 4

    if byte_size(pixels) >= expected do
      <<raw::binary-size(expected), _rest::binary>> = pixels
      {:ok, Sprite.new(width, height, bgra_to_rgba(raw))}
    else
      {:error, :truncated_tga_data}
    end
  end

  defp decode_tga_pixels(_pixels, _width, _height, bpp) do
    {:error, {:unsupported_tga_bpp, bpp}}
  end

  # TGA stores pixels in BGR / BGRA order; convert to RGBA for OpenGL.

  @spec bgr_to_rgba(binary()) :: binary()
  defp bgr_to_rgba(data), do: bgr_to_rgba(data, [])

  defp bgr_to_rgba(<<b::8, g::8, r::8, rest::binary>>, acc),
    do: bgr_to_rgba(rest, [acc, <<r::8, g::8, b::8, 255::8>>])

  defp bgr_to_rgba(<<>>, acc), do: :erlang.iolist_to_binary(acc)

  @spec bgra_to_rgba(binary()) :: binary()
  defp bgra_to_rgba(data), do: bgra_to_rgba(data, [])

  defp bgra_to_rgba(<<b::8, g::8, r::8, a::8, rest::binary>>, acc),
    do: bgra_to_rgba(rest, [acc, <<r::8, g::8, b::8, a::8>>])

  defp bgra_to_rgba(<<>>, acc), do: :erlang.iolist_to_binary(acc)

  # Flip sprite pixel rows vertically (for bottom-to-top TGA files).
  # Iterates rows 0 → h-1, prepending each to the accumulator so that the
  # last row ends up first — effectively reversing the row order.
  @spec vflip(Sprite.t()) :: Sprite.t()
  defp vflip(%Sprite{width: w, height: h, pixels: pixels} = sprite) do
    row_size = w * 4

    flipped =
      for i <- 0..(h - 1), reduce: [] do
        acc -> [binary_part(pixels, i * row_size, row_size) | acc]
      end

    %{sprite | pixels: :erlang.iolist_to_binary(flipped)}
  end
end
