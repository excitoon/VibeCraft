defmodule VibeCraft.Assets.SpriteTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.Sprite

  describe "new/3" do
    test "creates a valid 1×1 sprite" do
      pixels = <<255, 0, 0, 255>>
      sprite = Sprite.new(1, 1, pixels)
      assert sprite.width == 1
      assert sprite.height == 1
      assert sprite.pixels == pixels
    end

    test "creates a valid 2×2 sprite" do
      pixels = :binary.copy(<<0, 255, 0, 128>>, 4)
      sprite = Sprite.new(2, 2, pixels)
      assert sprite.width == 2
      assert sprite.height == 2
      assert byte_size(sprite.pixels) == 16
    end

    test "raises ArgumentError when pixel binary is too short" do
      assert_raise ArgumentError, ~r/expected 4 bytes/, fn ->
        Sprite.new(1, 1, <<255, 0, 0>>)
      end
    end

    test "raises ArgumentError when pixel binary is too long" do
      assert_raise ArgumentError, ~r/expected 4 bytes/, fn ->
        Sprite.new(1, 1, <<255, 0, 0, 255, 0>>)
      end
    end

    test "raises ArgumentError for dimension / data mismatch" do
      assert_raise ArgumentError, ~r/expected 16 bytes/, fn ->
        Sprite.new(2, 2, <<1, 2, 3, 4>>)
      end
    end
  end
end
