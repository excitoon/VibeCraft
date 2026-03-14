defmodule VibeCraft.Terrain do
  @moduledoc """
  3-D terrain height-map and normal-map data for Phase 3.

  A `Terrain` holds per-tile elevation values (0.0–1.0) and pre-computed
  surface normals used by the renderer for normal mapping and lighting.

  Normals are recomputed automatically whenever an elevation changes, so the
  renderer always has up-to-date data without a separate pass.

  ## Usage

      terrain = Terrain.new(32, 32)
      {:ok, terrain} = Terrain.set_elevation(terrain, {5, 3}, 0.75)
      0.75           = Terrain.elevation_at(terrain, {5, 3})
      {_nx, _ny, 1.0} = Terrain.normal_at(Terrain.new(4, 4), {0, 0})
  """

  @type position :: {non_neg_integer(), non_neg_integer()}
  @type elevation :: float()
  @type normal :: {float(), float(), float()}

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          elevations: %{position() => elevation()},
          normals: %{position() => normal()}
        }

  @enforce_keys [:width, :height]
  defstruct [:width, :height, elevations: %{}, normals: %{}]

  @default_elevation 0.0
  @default_normal {0.0, 0.0, 1.0}

  @doc """
  Create a flat terrain grid of `width × height` tiles.

  All elevations default to `0.0` and all normals point straight up
  `{0.0, 0.0, 1.0}` (the flat-terrain normal).
  """
  @spec new(pos_integer(), pos_integer()) :: t()
  def new(width, height) do
    elevations =
      for r <- 0..(height - 1), c <- 0..(width - 1), into: %{} do
        {{c, r}, @default_elevation}
      end

    normals =
      for r <- 0..(height - 1), c <- 0..(width - 1), into: %{} do
        {{c, r}, @default_normal}
      end

    %__MODULE__{width: width, height: height, elevations: elevations, normals: normals}
  end

  @doc """
  Return the elevation at `pos`.

  Returns `0.0` when `pos` is out of bounds.
  """
  @spec elevation_at(t(), position()) :: elevation()
  def elevation_at(%__MODULE__{elevations: elevations}, pos) do
    Map.get(elevations, pos, @default_elevation)
  end

  @doc """
  Return the pre-computed surface normal at `pos`.

  Returns `{0.0, 0.0, 1.0}` (straight up) when `pos` is out of bounds.
  """
  @spec normal_at(t(), position()) :: normal()
  def normal_at(%__MODULE__{normals: normals}, pos) do
    Map.get(normals, pos, @default_normal)
  end

  @doc """
  Set the elevation at `pos` to `value` and recompute affected normals.

  `value` is clamped to the range `0.0..1.0`.  Returns
  `{:error, :out_of_bounds}` when `pos` is outside the terrain.
  """
  @spec set_elevation(t(), position(), elevation()) :: {:ok, t()} | {:error, :out_of_bounds}
  def set_elevation(%__MODULE__{width: w, height: h} = terrain, {c, r} = pos, value)
      when c >= 0 and c < w and r >= 0 and r < h do
    clamped = max(0.0, min(1.0, value))
    terrain = %{terrain | elevations: Map.put(terrain.elevations, pos, clamped)}
    {:ok, %{terrain | normals: recompute_normals_around(terrain, pos)}}
  end

  def set_elevation(_terrain, _pos, _value), do: {:error, :out_of_bounds}

  # ── Private helpers ─────────────────────────────────────────────────────

  @spec recompute_normals_around(t(), position()) :: %{position() => normal()}
  defp recompute_normals_around(%__MODULE__{width: w, height: h} = terrain, {c, r}) do
    affected =
      for dr <- -1..1, dc <- -1..1,
          nr = r + dr,
          nc = c + dc,
          nr >= 0 and nr < h and nc >= 0 and nc < w do
        {nc, nr}
      end

    Enum.reduce(affected, terrain.normals, fn pos, acc ->
      Map.put(acc, pos, compute_normal(terrain, pos))
    end)
  end

  @spec compute_normal(t(), position()) :: normal()
  defp compute_normal(terrain, {c, r}) do
    left = elevation_at(terrain, {c - 1, r})
    right = elevation_at(terrain, {c + 1, r})
    above = elevation_at(terrain, {c, r - 1})
    below = elevation_at(terrain, {c, r + 1})

    dx = left - right
    dy = above - below
    dz = 2.0
    len = :math.sqrt(dx * dx + dy * dy + dz * dz)

    {dx / len, dy / len, dz / len}
  end
end
