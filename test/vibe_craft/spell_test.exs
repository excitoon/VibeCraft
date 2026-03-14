defmodule VibeCraft.SpellTest do
  use ExUnit.Case, async: true

  alias VibeCraft.{Spell, Unit}

  defp paladin, do: Unit.new(1, :paladin, :player1, {0, 0})
  defp death_knight, do: Unit.new(2, :death_knight, :player2, {1, 0})
  defp footman, do: Unit.new(3, :footman, :player1, {2, 0})

  describe "get/1" do
    test "returns a spell struct for each defined spell" do
      for name <- [:holy_light, :resurrect, :death_coil, :animate_dead] do
        spell = Spell.get(name)
        assert spell.name == name
        assert spell.mana_cost > 0
      end
    end
  end

  describe "can_cast?/2" do
    test "returns true when the caster has enough mana" do
      caster = paladin()
      assert Spell.can_cast?(caster, :holy_light)
    end

    test "returns false when the caster lacks mana" do
      caster = %{paladin() | mana: 0}
      refute Spell.can_cast?(caster, :holy_light)
    end

    test "returns false for units without a mana pool" do
      refute Spell.can_cast?(footman(), :holy_light)
    end
  end

  describe "cast/3 — :holy_light" do
    test "heals the target and deducts mana from the caster" do
      caster = paladin()
      injured = %{footman() | hp: 10}
      assert {:ok, caster_after, healed} = Spell.cast(caster, :holy_light, injured)
      assert healed.hp > injured.hp
      assert caster_after.mana < caster.mana
    end

    test "healing does not exceed target max_hp" do
      caster = paladin()
      target = footman()
      # Target is at full HP; hp should stay capped at max_hp.
      assert {:ok, _caster, healed} = Spell.cast(caster, :holy_light, target)
      assert healed.hp <= healed.max_hp
    end
  end

  describe "cast/3 — :death_coil" do
    test "deals damage to the target" do
      caster = death_knight()
      target = footman()
      assert {:ok, _caster, damaged} = Spell.cast(caster, :death_coil, target)
      assert damaged.hp < target.hp
    end

    test "damage does not reduce target below zero hp" do
      caster = death_knight()
      target = %{footman() | hp: 1}
      assert {:ok, _caster, damaged} = Spell.cast(caster, :death_coil, target)
      assert damaged.hp == 0
    end
  end

  describe "cast/3 — insufficient mana" do
    test "returns error when caster cannot afford the spell" do
      caster = %{paladin() | mana: 0}
      assert {:error, :insufficient_mana} = Spell.cast(caster, :holy_light, footman())
    end
  end
end
