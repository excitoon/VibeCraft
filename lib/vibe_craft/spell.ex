defmodule VibeCraft.Spell do
  @moduledoc """
  Spell definitions and mana-based casting for Phase 2.

  Spells are cast by hero units that have a mana pool.  Each spell costs a
  fixed amount of mana from the caster and applies an effect to a target unit.

  ## Available spells

  | Name            | Mana cost | Effect                              |
  |-----------------|-----------|-------------------------------------|
  | `:holy_light`   | 65        | Heal an allied unit for 200 HP      |
  | `:resurrect`    | 200       | Restore a fallen allied unit (stub) |
  | `:death_coil`   | 50        | Deal 100 damage to an enemy unit    |
  | `:animate_dead` | 125       | Raise an enemy corpse (stub)        |

  ## Usage

      iex> paladin = Unit.new(1, :paladin, :player1, {0, 0})
      iex> injured = %{Unit.new(2, :footman, :player1, {1, 0}) | hp: 10}
      iex> {:ok, updated_caster, healed} = Spell.cast(paladin, :holy_light, injured)
      iex> healed.hp
      60
  """

  alias VibeCraft.Unit

  @type spell_name :: :holy_light | :resurrect | :death_coil | :animate_dead

  @type t :: %__MODULE__{
          name: spell_name(),
          mana_cost: pos_integer(),
          effect: :heal | :damage | :stub
        }

  @enforce_keys [:name, :mana_cost, :effect]
  defstruct [:name, :mana_cost, :effect]

  @definitions %{
    holy_light: %{mana_cost: 65, effect: :heal},
    resurrect: %{mana_cost: 200, effect: :stub},
    death_coil: %{mana_cost: 50, effect: :damage},
    animate_dead: %{mana_cost: 125, effect: :stub}
  }

  @heal_amount 200
  @damage_amount 100

  @doc "Return the spell definition for `name`."
  @spec get(spell_name()) :: t()
  def get(name) do
    %{mana_cost: cost, effect: effect} = Map.fetch!(@definitions, name)
    %__MODULE__{name: name, mana_cost: cost, effect: effect}
  end

  @doc """
  Return `true` when `unit` has enough mana to cast `spell_name`.
  """
  @spec can_cast?(Unit.t(), spell_name()) :: boolean()
  def can_cast?(%Unit{mana: mana}, spell_name) do
    spell = get(spell_name)
    mana >= spell.mana_cost
  end

  @doc """
  Cast `spell_name` from `caster` onto `target`.

  On success returns `{:ok, updated_caster, updated_target}`.  The caster's
  mana is reduced by the spell's cost.

  Returns `{:error, :insufficient_mana}` when the caster cannot afford the
  spell, or `{:error, :invalid_target}` for spells that require a specific
  target type (e.g. `:resurrect` on a living unit).
  """
  @spec cast(Unit.t(), spell_name(), Unit.t()) ::
          {:ok, Unit.t(), Unit.t()} | {:error, :insufficient_mana | :invalid_target}
  def cast(caster, spell_name, target) do
    spell = get(spell_name)

    with {:ok, caster_after} <- Unit.spend_mana(caster, spell.mana_cost) do
      {:ok, caster_after, apply_effect(spell, target)}
    end
  end

  # ── Private helpers ─────────────────────────────────────────────────────

  @spec apply_effect(t(), Unit.t()) :: Unit.t()
  defp apply_effect(%__MODULE__{effect: :heal}, target) do
    %{target | hp: min(target.hp + @heal_amount, target.max_hp)}
  end

  defp apply_effect(%__MODULE__{effect: :damage}, target) do
    %{target | hp: max(0, target.hp - @damage_amount)}
  end

  defp apply_effect(%__MODULE__{effect: :stub}, target), do: target
end
