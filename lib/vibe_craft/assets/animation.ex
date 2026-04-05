defmodule VibeCraft.Assets.Animation do
  @moduledoc """
  Skeletal animation data parsed from BVH (Biovision Hierarchy) files.

  A BVH animation stores a joint hierarchy (skeleton) together with
  per-frame channel values that drive the skeleton's motion.

  ## Fields

  - `joints`     — ordered list of joint maps, each containing:
    - `:name`     — joint name (`String.t()`)
    - `:parent`   — parent joint name, or `nil` for the root
    - `:offset`   — rest-pose offset `{x, y, z}` from parent
    - `:channels` — ordered list of channel atoms, e.g.
      `[:x_position, :y_position, :z_position, :z_rotation, :x_rotation, :y_rotation]`
  - `frames`     — list of frames; each frame is a flat list of floats,
    one value per channel in hierarchy order.
  - `frame_time` — seconds per frame (e.g. 0.033333 for 30 fps).
  """

  @enforce_keys [:joints, :frames, :frame_time]
  defstruct joints: [],
            frames: [],
            frame_time: 0.0

  @type joint :: %{
          name: String.t(),
          parent: String.t() | nil,
          offset: {float(), float(), float()},
          channels: [atom()]
        }

  @type frame :: [float()]

  @type t :: %__MODULE__{
          joints: [joint()],
          frames: [frame()],
          frame_time: float()
        }

  @doc """
  Create a new animation from skeleton and motion data.

  Raises `ArgumentError` when `joints` or `frames` is empty, or when
  `frame_time` is not positive.
  """
  @spec new([joint()], [frame()], float()) :: t()
  def new(joints, frames, frame_time)

  def new([], _frames, _frame_time) do
    raise ArgumentError, "joints must not be empty"
  end

  def new(_joints, [], _frame_time) do
    raise ArgumentError, "frames must not be empty"
  end

  def new(_joints, _frames, frame_time) when frame_time <= 0 do
    raise ArgumentError, "frame_time must be positive"
  end

  def new(joints, frames, frame_time)
      when is_list(joints) and is_list(frames) and is_float(frame_time) do
    %__MODULE__{
      joints: joints,
      frames: frames,
      frame_time: frame_time
    }
  end
end
