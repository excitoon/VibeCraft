defmodule VibeCraft.Assets.BvhLoaderTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.{Animation, BvhLoader}

  # ── helpers ──────────────────────────────────────────────────────────────

  defp tmp(name), do: Path.join(System.tmp_dir!(), "vibe_craft_bvh_test_#{name}")

  defp write_tmp(name, data) do
    path = tmp(name)
    File.write!(path, data)
    on_exit(fn -> File.rm(path) end)
    path
  end

  # ── parse/1 ─────────────────────────────────────────────────────────────

  describe "parse/1" do
    test "parses a minimal single-joint BVH" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
        End Site
        {
          OFFSET 0.0 1.0 0.0
        }
      }
      MOTION
      Frames: 2
      Frame Time: 0.033333
      0.0 0.0 0.0 0.0 0.0 0.0
      0.0 1.0 0.0 0.0 0.0 0.0
      """

      assert {:ok, %Animation{} = anim} = BvhLoader.parse(bvh)
      assert length(anim.joints) == 1
      assert length(anim.frames) == 2
      assert anim.frame_time == 0.033333

      [root] = anim.joints
      assert root.name == "Hips"
      assert root.parent == nil
      assert root.offset == {0.0, 0.0, 0.0}
      assert length(root.channels) == 6
    end

    test "parses a skeleton with child joints" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
        JOINT Spine
        {
          OFFSET 0.0 0.2 0.0
          CHANNELS 3 Zrotation Xrotation Yrotation
          End Site
          {
            OFFSET 0.0 0.3 0.0
          }
        }
      }
      MOTION
      Frames: 1
      Frame Time: 0.033333
      0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
      """

      assert {:ok, %Animation{} = anim} = BvhLoader.parse(bvh)
      assert length(anim.joints) == 2

      [hips, spine] = anim.joints
      assert hips.name == "Hips"
      assert hips.parent == nil
      assert spine.name == "Spine"
      assert spine.parent == "Hips"
      assert spine.offset == {0.0, 0.2, 0.0}
    end

    test "parses channel names into atoms" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
        End Site
        {
          OFFSET 0.0 1.0 0.0
        }
      }
      MOTION
      Frames: 1
      Frame Time: 0.033333
      0.0 0.0 0.0 0.0 0.0 0.0
      """

      assert {:ok, anim} = BvhLoader.parse(bvh)
      [root] = anim.joints

      assert root.channels == [
               :x_position,
               :y_position,
               :z_position,
               :z_rotation,
               :x_rotation,
               :y_rotation
             ]
    end

    test "parses frame data correctly" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 3 Xposition Yposition Zposition
        End Site
        {
          OFFSET 0.0 1.0 0.0
        }
      }
      MOTION
      Frames: 3
      Frame Time: 0.041667
      1.0 2.0 3.0
      4.0 5.0 6.0
      7.0 8.0 9.0
      """

      assert {:ok, anim} = BvhLoader.parse(bvh)
      assert anim.frame_time == 0.041667
      assert length(anim.frames) == 3
      assert Enum.at(anim.frames, 0) == [1.0, 2.0, 3.0]
      assert Enum.at(anim.frames, 1) == [4.0, 5.0, 6.0]
      assert Enum.at(anim.frames, 2) == [7.0, 8.0, 9.0]
    end

    test "handles Windows-style line endings" do
      bvh =
        "HIERARCHY\r\nROOT Hips\r\n{\r\n  OFFSET 0.0 0.0 0.0\r\n  CHANNELS 3 Xposition Yposition Zposition\r\n  End Site\r\n  {\r\n    OFFSET 0.0 1.0 0.0\r\n  }\r\n}\r\nMOTION\r\nFrames: 1\r\nFrame Time: 0.033333\r\n0.0 0.0 0.0\r\n"

      assert {:ok, %Animation{}} = BvhLoader.parse(bvh)
    end

    test "returns error for missing HIERARCHY keyword" do
      bvh = """
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 3 Xposition Yposition Zposition
      }
      MOTION
      Frames: 1
      Frame Time: 0.033333
      0.0 0.0 0.0
      """

      assert {:error, {:expected, "HIERARCHY"}} = BvhLoader.parse(bvh)
    end

    test "returns error for missing MOTION keyword" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 3 Xposition Yposition Zposition
        End Site
        {
          OFFSET 0.0 1.0 0.0
        }
      }
      """

      assert {:error, {:expected, "MOTION"}} = BvhLoader.parse(bvh)
    end
  end

  # ── load/1 ──────────────────────────────────────────────────────────────

  describe "load/1" do
    test "loads a valid .bvh file from disk" do
      bvh = """
      HIERARCHY
      ROOT Hips
      {
        OFFSET 0.0 0.0 0.0
        CHANNELS 3 Xposition Yposition Zposition
        End Site
        {
          OFFSET 0.0 1.0 0.0
        }
      }
      MOTION
      Frames: 1
      Frame Time: 0.033333
      0.0 0.0 0.0
      """

      path = write_tmp("simple.bvh", bvh)
      assert {:ok, %Animation{}} = BvhLoader.load(path)
    end

    test "returns error when file does not exist" do
      assert {:error, :enoent} = BvhLoader.load("/nonexistent/path/anim.bvh")
    end

    test "loads the built-in fighter_idle.bvh animation" do
      path = Application.app_dir(:vibe_craft, "priv/animations/fighter_idle.bvh")
      assert {:ok, %Animation{} = anim} = BvhLoader.load(path)

      # Fighter skeleton should have multiple joints
      assert length(anim.joints) >= 10

      # Should have 60 frames at ~30fps
      assert length(anim.frames) == 60
      assert_in_delta anim.frame_time, 0.033333, 0.001

      # Root joint should be Hips
      [root | _] = anim.joints
      assert root.name == "Hips"
      assert root.parent == nil

      # All frames should have the same channel count
      total_channels =
        Enum.reduce(anim.joints, 0, fn j, acc -> acc + length(j.channels) end)

      for frame <- anim.frames do
        assert length(frame) == total_channels
      end
    end
  end
end
