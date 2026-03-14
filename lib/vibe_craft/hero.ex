defmodule VibeCraft.Hero do
  @moduledoc """
  Hero experience and leveling system for Phase 2.

  Heroes are special units (`:paladin` and `:death_knight`) that accumulate
  experience points (XP) by defeating enemies.  When enough XP is gathered,
  the hero levels up and gains improved statistics.

  ## XP thresholds

  | Level | XP required |
  |-------|-------------|
  | 1     | 0           |
  | 2     | 200         |
  | 3     | 500         |
  | 4     | 1 000       |
  | 5     | 2 000       |
  | 6     | 4 000       |
  | 7     | 8 000       |
  | 8     | 16 000      |
  | 9     | 30 000      |

  ## Per-level bonuses

  Each level above 1 grants: +50 max HP, +2 attack, +25 max mana.
  The hero is also healed for the HP increase (up to the new maximum).
  """

  alias VibeCraft.Unit

  @xp_thresholds [0, 200, 500, 1_000, 2_000, 4_000, 8_000, 16_000, 30_000]

  @max_level length(@xp_thresholds)

  @doc """
  Grant `xp_gained` experience to `unit` and apply any resulting level-ups.

  Works for any unit type; only hero units start with a mana pool, but all
  units track `xp` and `level` so that XP can be granted uniformly.
  """
  @spec gain_xp(Unit.t(), non_neg_integer()) :: Unit.t()
  def gain_xp(%Unit{} = unit, xp_gained) do
    unit = Unit.add_xp(unit, xp_gained)
    new_level = level_for_xp(unit.xp)

    if new_level > unit.level do
      apply_levels(unit, unit.level + 1, new_level)
    else
      unit
    end
  end

  @doc """
  Return the level that corresponds to `xp` total experience.

  The maximum level is #{@max_level}.
  """
  @spec level_for_xp(non_neg_integer()) :: pos_integer()
  def level_for_xp(xp) do
    Enum.count(@xp_thresholds, &(&1 <= xp))
  end

  @doc "Return the XP required to reach `level`."
  @spec xp_for_level(pos_integer()) :: non_neg_integer()
  def xp_for_level(level) when level >= 1 and level <= @max_level do
    Enum.at(@xp_thresholds, level - 1)
  end

  # ── Private helpers ─────────────────────────────────────────────────────

  # Apply level-ups one at a time from `from_level` to `to_level`.
  @spec apply_levels(Unit.t(), pos_integer(), pos_integer()) :: Unit.t()
  defp apply_levels(unit, from_level, to_level) when from_level > to_level, do: unit

  defp apply_levels(unit, from_level, to_level) do
    unit
    |> apply_single_level_up()
    |> apply_levels(from_level + 1, to_level)
  end

  @spec apply_single_level_up(Unit.t()) :: Unit.t()
  defp apply_single_level_up(unit) do
    new_max_hp = unit.max_hp + 50
    new_max_mana = unit.max_mana + 25

    %{
      unit
      | level: unit.level + 1,
        max_hp: new_max_hp,
        hp: min(unit.hp + 50, new_max_hp),
        attack: unit.attack + 2,
        max_mana: new_max_mana,
        mana: min(unit.mana + 25, new_max_mana)
    }
  end
end
