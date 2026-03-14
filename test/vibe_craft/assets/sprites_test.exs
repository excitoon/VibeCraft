defmodule VibeCraft.Assets.SpritesTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.{Sprite, Sprites}

  describe "cursor/0" do
    test "returns a 16×16 RGBA sprite" do
      sprite = Sprites.cursor()
      assert %Sprite{width: 16, height: 16} = sprite
      assert byte_size(sprite.pixels) == 16 * 16 * 4
    end

    test "pixel data contains only fully-opaque or fully-transparent pixels" do
      sprite = Sprites.cursor()

      for <<_r::8, _g::8, _b::8, a::8 <- sprite.pixels>> do
        assert a == 0 or a == 255,
               "expected alpha to be 0 or 255, got #{a}"
      end
    end

    test "outline pixels are black" do
      sprite = Sprites.cursor()

      for <<r::8, g::8, b::8, a::8 <- sprite.pixels>>, a == 255 do
        assert r == 0 or r == 255,
               "expected opaque pixel to be black or white, got R=#{r} G=#{g} B=#{b}"
      end
    end

    test "top-left pixel is black opaque (cursor tip)" do
      %Sprite{pixels: pixels} = Sprites.cursor()
      <<r::8, g::8, b::8, a::8, _rest::binary>> = pixels
      assert {r, g, b, a} == {0, 0, 0, 255}
    end
  end
end
