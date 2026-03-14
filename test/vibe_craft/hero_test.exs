defmodule VibeCraft.HeroTest do
  use ExUnit.Case, async: true

  alias VibeCraft.{Hero, Unit}

  defp paladin, do: Unit.new(1, :paladin, :player1, {0, 0})

  describe "level_for_xp/1" do
    test "returns level 1 for 0 xp" do
      assert Hero.level_for_xp(0) == 1
    end

    test "returns level 2 at the 200 xp threshold" do
      assert Hero.level_for_xp(200) == 2
    end

    test "returns level 3 at the 500 xp threshold" do
      assert Hero.level_for_xp(500) == 3
    end

    test "returns level 9 at the 30 000 xp threshold" do
      assert Hero.level_for_xp(30_000) == 9
    end

    test "returns level 1 for xp just below level 2 threshold" do
      assert Hero.level_for_xp(199) == 1
    end
  end

  describe "xp_for_level/1" do
    test "level 1 requires 0 xp" do
      assert Hero.xp_for_level(1) == 0
    end

    test "level 2 requires 200 xp" do
      assert Hero.xp_for_level(2) == 200
    end

    test "level 9 requires 30 000 xp" do
      assert Hero.xp_for_level(9) == 30_000
    end
  end

  describe "gain_xp/2" do
    test "accumulates xp without leveling up when below threshold" do
      hero = paladin()
      updated = Hero.gain_xp(hero, 100)
      assert updated.xp == 100
      assert updated.level == 1
    end

    test "levels up hero when xp threshold is crossed" do
      hero = paladin()
      updated = Hero.gain_xp(hero, 200)
      assert updated.level == 2
    end

    test "increases max_hp and attack on level-up" do
      hero = paladin()
      updated = Hero.gain_xp(hero, 200)
      assert updated.max_hp > hero.max_hp
      assert updated.attack > hero.attack
    end

    test "increases max_mana on level-up for heroes" do
      hero = paladin()
      updated = Hero.gain_xp(hero, 200)
      assert updated.max_mana > hero.max_mana
    end

    test "can level up multiple times in one gain_xp call" do
      hero = paladin()
      # 1 000 xp crosses thresholds for levels 2, 3, and 4.
      updated = Hero.gain_xp(hero, 1_000)
      assert updated.level == 4
    end

    test "works on non-hero ground units (accumulates xp, no mana change)" do
      unit = Unit.new(2, :footman, :player1, {1, 0})
      updated = Hero.gain_xp(unit, 100)
      assert updated.xp == 100
      assert updated.max_mana == 0
    end
  end
end
