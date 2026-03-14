defmodule VibeCraft.DayNight do
  @moduledoc """
  Day/night cycle and dynamic lighting for Phase 3.

  The cycle advances one tick at a time.  Each tick maps to a named phase
  and an ambient RGB colour that the renderer blends over the scene to
  simulate changing light conditions.

  ## Default cycle (600 ticks)

  | Phase     | Fraction of cycle | Ambient colour  |
  |-----------|--------------------|-----------------|
  | `:dawn`   | 0–24 %             | warm orange     |
  | `:day`    | 25–74 %            | bright white    |
  | `:dusk`   | 75–87 %            | amber           |
  | `:night`  | 88–99 %            | deep blue       |

  ## Usage

      cycle = DayNight.new()
      cycle = DayNight.tick(cycle)
      :day  = DayNight.phase(cycle)
      {1.0, 1.0, 1.0} = DayNight.ambient_color(cycle)
  """

  @type phase :: :dawn | :day | :dusk | :night
  @type color :: {float(), float(), float()}

  @type t :: %__MODULE__{
          tick: non_neg_integer(),
          cycle_length: pos_integer()
        }

  @enforce_keys [:cycle_length]
  defstruct [:cycle_length, tick: 0]

  @default_cycle 600

  @doc "Create a new day/night cycle with an optional `cycle_length` in ticks."
  @spec new(pos_integer()) :: t()
  def new(cycle_length \\ @default_cycle) do
    %__MODULE__{cycle_length: cycle_length, tick: 0}
  end

  @doc "Advance the cycle by one tick, wrapping back to 0 at the end of the cycle."
  @spec tick(t()) :: t()
  def tick(%__MODULE__{tick: t, cycle_length: len} = cycle) do
    %{cycle | tick: rem(t + 1, len)}
  end

  @doc "Return the current phase of the cycle."
  @spec phase(t()) :: phase()
  def phase(%__MODULE__{tick: tick, cycle_length: len}) do
    phase_for_progress(tick / len)
  end

  @doc """
  Return the ambient RGB colour `{r, g, b}` for the current cycle position.

  Each channel is a float in `0.0..1.0`.
  """
  @spec ambient_color(t()) :: color()
  def ambient_color(%__MODULE__{} = cycle) do
    color_for_phase(phase(cycle))
  end

  # ── Private helpers ─────────────────────────────────────────────────────

  @spec phase_for_progress(float()) :: phase()
  defp phase_for_progress(p) when p < 0.25, do: :dawn
  defp phase_for_progress(p) when p < 0.75, do: :day
  defp phase_for_progress(p) when p < 0.875, do: :dusk
  defp phase_for_progress(_p), do: :night

  @spec color_for_phase(phase()) :: color()
  defp color_for_phase(:dawn), do: {1.0, 0.75, 0.5}
  defp color_for_phase(:day), do: {1.0, 1.0, 1.0}
  defp color_for_phase(:dusk), do: {1.0, 0.6, 0.2}
  defp color_for_phase(:night), do: {0.1, 0.1, 0.4}
end
