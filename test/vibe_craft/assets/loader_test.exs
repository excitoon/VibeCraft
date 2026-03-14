defmodule VibeCraft.Assets.LoaderTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.{Loader, Sprite}

  # ── helpers ──────────────────────────────────────────────────────────────

  defp tmp(name), do: Path.join(System.tmp_dir!(), "vibe_craft_test_#{name}")

  defp write_tmp(name, data) do
    path = tmp(name)
    File.write!(path, data)
    on_exit(fn -> File.rm(path) end)
    path
  end

  # ── .rgba ─────────────────────────────────────────────────────────────────

  describe "load/1 with .rgba format" do
    test "loads a valid 2×2 .rgba file" do
      pixels = :binary.copy(<<255, 0, 0, 255>>, 4)
      data = <<2::32-big, 2::32-big, pixels::binary>>
      path = write_tmp("ok.rgba", data)

      assert {:ok, %Sprite{width: 2, height: 2, pixels: ^pixels}} = Loader.load(path)
    end

    test "loads the built-in cursor.rgba asset" do
      path = Application.app_dir(:vibe_craft, "priv/sprites/cursor.rgba")
      assert {:ok, %Sprite{width: 16, height: 16}} = Loader.load(path)
    end

    test "returns error when .rgba pixel data is truncated" do
      data = <<2::32-big, 2::32-big, 0, 0, 0, 255>>
      path = write_tmp("short.rgba", data)

      assert {:error, {:invalid_rgba_data, expected: 16, got: 4}} = Loader.load(path)
    end

    test "returns error for malformed .rgba header" do
      path = write_tmp("bad.rgba", <<0, 1>>)
      assert {:error, :invalid_rgba_header} = Loader.load(path)
    end
  end

  # ── .tga ──────────────────────────────────────────────────────────────────

  # Helper: build a minimal 2×2 uncompressed true-color TGA.
  # `bpp` is 24 or 32; `top_to_bottom` sets image_desc bit 5.
  defp build_tga(pixel_data, bpp, top_to_bottom \\ true) do
    image_desc = if top_to_bottom, do: 0x20, else: 0x00
    # id_len=0, cmap=0, type=2, cmap_spec(5)=0, xorg=0, yorg=0, w=2, h=2
    header = <<0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2::16-little, 2::16-little, bpp, image_desc>>
    header <> pixel_data
  end

  describe "load/1 with .tga format (24-bit)" do
    test "loads a valid top-to-bottom 24-bit TGA" do
      # 4 pixels in BGR: red, green, blue, white
      pixel_data = <<0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255>>
      path = write_tmp("ok24.tga", build_tga(pixel_data, 24))

      assert {:ok, %Sprite{width: 2, height: 2, pixels: rgba}} = Loader.load(path)
      # first pixel BGR(0,0,255) → RGBA(255,0,0,255) = red
      assert <<255, 0, 0, 255, _rest::binary>> = rgba
    end

    test "loads a bottom-to-top 24-bit TGA and flips correctly" do
      # Row 0 = red, row 1 = green (in file; after flip: row 0 = green, row 1 = red)
      red_bgr = <<0, 0, 255, 0, 0, 255>>
      grn_bgr = <<0, 255, 0, 0, 255, 0>>
      pixel_data = red_bgr <> grn_bgr
      path = write_tmp("flip24.tga", build_tga(pixel_data, 24, false))

      assert {:ok, %Sprite{pixels: rgba}} = Loader.load(path)
      # After flip, first two pixels should be green, next two red.
      assert <<0, 255, 0, 255, 0, 255, 0, 255, 255, 0, 0, 255, 255, 0, 0, 255>> = rgba
    end

    test "returns error for truncated 24-bit TGA" do
      path = write_tmp("trunc24.tga", build_tga(<<0, 0, 255>>, 24))
      assert {:error, :truncated_tga_data} = Loader.load(path)
    end
  end

  describe "load/1 with .tga format (32-bit)" do
    test "loads a valid top-to-bottom 32-bit TGA" do
      # 4 pixels in BGRA: semi-transparent red
      pixel_data = :binary.copy(<<0, 0, 255, 128>>, 4)
      path = write_tmp("ok32.tga", build_tga(pixel_data, 32))

      assert {:ok, %Sprite{width: 2, height: 2, pixels: rgba}} = Loader.load(path)
      <<255, 0, 0, 128, _rest::binary>> = rgba
    end

    test "returns error for unsupported bits-per-pixel" do
      pixel_data = :binary.copy(<<0, 0>>, 4)
      path = write_tmp("bpp16.tga", build_tga(pixel_data, 16))
      assert {:error, {:unsupported_tga_bpp, 16}} = Loader.load(path)
    end
  end

  # ── unsupported / missing ──────────────────────────────────────────────────

  describe "load/1 error cases" do
    test "returns error for unsupported file extension" do
      path = write_tmp("sprite.png", "not a real png")
      assert {:error, {:unsupported_format, ".png"}} = Loader.load(path)
    end

    test "returns error when file does not exist" do
      assert {:error, :enoent} = Loader.load("/nonexistent/path/sprite.rgba")
    end
  end
end
