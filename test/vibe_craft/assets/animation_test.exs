defmodule VibeCraft.Assets.AnimationTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.Animation

  describe "new/3" do
    test "creates an animation with joints, frames, and frame_time" do
      joints = [
        %{name: "Hips", parent: nil, offset: {0.0, 0.0, 0.0}, channels: [:y_position]}
      ]

      frames = [[1.0]]
      anim = Animation.new(joints, frames, 0.033333)

      assert anim.joints == joints
      assert anim.frames == frames
      assert anim.frame_time == 0.033333
    end

    test "raises ArgumentError when joints is empty" do
      assert_raise ArgumentError, ~r/joints must not be empty/, fn ->
        Animation.new([], [[1.0]], 0.033333)
      end
    end

    test "raises ArgumentError when frames is empty" do
      joints = [
        %{name: "Hips", parent: nil, offset: {0.0, 0.0, 0.0}, channels: [:y_position]}
      ]

      assert_raise ArgumentError, ~r/frames must not be empty/, fn ->
        Animation.new(joints, [], 0.033333)
      end
    end

    test "raises ArgumentError when frame_time is not positive" do
      joints = [
        %{name: "Hips", parent: nil, offset: {0.0, 0.0, 0.0}, channels: [:y_position]}
      ]

      assert_raise ArgumentError, ~r/frame_time must be positive/, fn ->
        Animation.new(joints, [[1.0]], 0.0)
      end

      assert_raise ArgumentError, ~r/frame_time must be positive/, fn ->
        Animation.new(joints, [[1.0]], -0.01)
      end
    end
  end
end
