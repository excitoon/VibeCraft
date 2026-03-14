defmodule VibeCraft.TerrainTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Terrain

  defp flat, do: Terrain.new(4, 4)

  describe "new/2" do
    test "creates terrain with correct dimensions" do
      terrain = Terrain.new(8, 6)
      assert terrain.width == 8
      assert terrain.height == 6
    end

    test "all elevations default to 0.0" do
      terrain = flat()
      assert Terrain.elevation_at(terrain, {0, 0}) == 0.0
      assert Terrain.elevation_at(terrain, {3, 3}) == 0.0
    end

    test "all normals default to straight up" do
      terrain = flat()
      assert Terrain.normal_at(terrain, {1, 1}) == {0.0, 0.0, 1.0}
    end
  end

  describe "elevation_at/2" do
    test "returns 0.0 for out-of-bounds position" do
      terrain = flat()
      assert Terrain.elevation_at(terrain, {99, 99}) == 0.0
    end
  end

  describe "normal_at/2" do
    test "returns default normal for out-of-bounds position" do
      terrain = flat()
      assert Terrain.normal_at(terrain, {99, 99}) == {0.0, 0.0, 1.0}
    end
  end

  describe "set_elevation/3" do
    test "sets elevation at a valid position" do
      {:ok, terrain} = Terrain.set_elevation(flat(), {1, 1}, 0.5)
      assert Terrain.elevation_at(terrain, {1, 1}) == 0.5
    end

    test "clamps elevation above 1.0 to 1.0" do
      {:ok, terrain} = Terrain.set_elevation(flat(), {0, 0}, 2.5)
      assert Terrain.elevation_at(terrain, {0, 0}) == 1.0
    end

    test "clamps elevation below 0.0 to 0.0" do
      {:ok, terrain} = Terrain.set_elevation(flat(), {0, 0}, -1.0)
      assert Terrain.elevation_at(terrain, {0, 0}) == 0.0
    end

    test "returns error for out-of-bounds position" do
      assert {:error, :out_of_bounds} = Terrain.set_elevation(flat(), {99, 99}, 0.5)
    end

    test "recomputes normals at the affected tile" do
      {:ok, terrain} = Terrain.set_elevation(flat(), {2, 2}, 1.0)
      {_nx, _ny, nz} = Terrain.normal_at(terrain, {2, 2})
      # nz is the z-component of the normal; it should remain positive
      assert nz > 0.0
    end

    test "normal at modified position is a unit vector" do
      {:ok, terrain} = Terrain.set_elevation(flat(), {2, 2}, 0.8)
      {nx, ny, nz} = Terrain.normal_at(terrain, {2, 2})
      length_sq = nx * nx + ny * ny + nz * nz
      assert_in_delta length_sq, 1.0, 1.0e-9
    end
  end
end
