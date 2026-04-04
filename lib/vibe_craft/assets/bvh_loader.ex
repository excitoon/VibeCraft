defmodule VibeCraft.Assets.BvhLoader do
  @moduledoc """
  BVH (Biovision Hierarchy) loader for skeletal animations.

  The [BVH format](https://research.cs.wisc.edu/graphics/Courses/cs-838-1999/Jeff/BVH.html)
  is a plain-text motion-capture format that stores a skeleton hierarchy
  and per-frame joint rotations / translations.  It is fully text-based,
  diffs cleanly in Git, and is supported by virtually every 3-D tool.

  ## Supported elements

  | Keyword       | Meaning                              |
  |---------------|--------------------------------------|
  | `HIERARCHY`   | Start of skeleton definition         |
  | `ROOT`        | Root joint                           |
  | `JOINT`       | Child joint                          |
  | `End Site`    | Terminal bone (leaf, no channels)    |
  | `OFFSET`      | Rest-pose offset from parent         |
  | `CHANNELS`    | Number and names of motion channels  |
  | `MOTION`      | Start of motion data                 |
  | `Frames:`     | Number of frames                     |
  | `Frame Time:` | Seconds per frame                    |

  Returns `{:ok, %VibeCraft.Assets.Animation{}}` or `{:error, reason}`.
  """

  alias VibeCraft.Assets.Animation

  @channel_map %{
    "Xposition" => :x_position,
    "Yposition" => :y_position,
    "Zposition" => :z_position,
    "Xrotation" => :x_rotation,
    "Yrotation" => :y_rotation,
    "Zrotation" => :z_rotation
  }

  @doc """
  Load a BVH animation from a file at `path`.
  """
  @spec load(Path.t()) :: {:ok, Animation.t()} | {:error, term()}
  def load(path) do
    with {:ok, data} <- File.read(path) do
      parse(data)
    end
  end

  @doc """
  Parse a BVH string into an `Animation` struct.
  """
  @spec parse(String.t()) :: {:ok, Animation.t()} | {:error, term()}
  def parse(data) when is_binary(data) do
    lines =
      data
      |> String.split(~r/\r?\n/)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    with {:ok, rest} <- expect_keyword(lines, "HIERARCHY"),
         {:ok, joints, rest} <- parse_hierarchy(rest),
         {:ok, rest} <- expect_keyword(rest, "MOTION"),
         {:ok, frame_count, rest} <- parse_frames_header(rest),
         {:ok, frame_time, rest} <- parse_frame_time(rest),
         {:ok, frames} <- parse_frame_data(rest, frame_count, total_channels(joints)) do
      {:ok, Animation.new(joints, frames, frame_time)}
    end
  end

  # ── hierarchy parsing ────────────────────────────────────────────────────

  defp parse_hierarchy(lines) do
    case lines do
      ["ROOT " <> name | rest] ->
        parse_joint(rest, String.trim(name), nil, [])

      _ ->
        {:error, :expected_root}
    end
  end

  defp parse_joint(["{" | rest], name, parent, acc) do
    joint = %{name: name, parent: parent, offset: {0.0, 0.0, 0.0}, channels: []}

    parse_joint_body(rest, joint, name, acc)
  end

  defp parse_joint(_lines, _name, _parent, _acc) do
    {:error, :expected_brace}
  end

  # `owner` is the name of the joint whose `{ ... }` block we are inside.
  # `joint` is the joint struct being assembled (nil after it was flushed to acc).

  defp parse_joint_body(["OFFSET " <> coords | rest], joint, owner, acc) when joint != nil do
    offset = parse_vec3(coords)
    parse_joint_body(rest, %{joint | offset: offset}, owner, acc)
  end

  defp parse_joint_body(["CHANNELS " <> spec | rest], joint, owner, acc) when joint != nil do
    channels = parse_channels(spec)
    parse_joint_body(rest, %{joint | channels: channels}, owner, acc)
  end

  defp parse_joint_body(["JOINT " <> child_name | rest], joint, owner, acc) do
    # Flush the current joint to acc if it hasn't been flushed yet.
    acc = if joint, do: acc ++ [joint], else: acc

    case parse_joint(rest, String.trim(child_name), owner, []) do
      {:ok, child_joints, rest} ->
        parse_joint_body(rest, nil, owner, acc ++ child_joints)

      error ->
        error
    end
  end

  defp parse_joint_body(["End Site" | rest], joint, owner, acc) do
    case skip_end_site(rest) do
      {:ok, rest} ->
        parse_joint_body(rest, joint, owner, acc)

      error ->
        error
    end
  end

  defp parse_joint_body(["}" | rest], nil, _owner, acc) do
    {:ok, acc, rest}
  end

  defp parse_joint_body(["}" | rest], joint, _owner, acc) do
    {:ok, acc ++ [joint], rest}
  end

  defp parse_joint_body([], _joint, _owner, _acc) do
    {:error, :unexpected_eof}
  end

  defp parse_joint_body([_unknown | rest], joint, owner, acc) do
    parse_joint_body(rest, joint, owner, acc)
  end

  defp skip_end_site(["{" | rest]) do
    skip_until_close(rest, 1)
  end

  defp skip_end_site(_), do: {:error, :expected_brace}

  defp skip_until_close(["}" | rest], 1), do: {:ok, rest}
  defp skip_until_close(["}" | rest], n), do: skip_until_close(rest, n - 1)
  defp skip_until_close(["{" | rest], n), do: skip_until_close(rest, n + 1)
  defp skip_until_close([_ | rest], n), do: skip_until_close(rest, n)
  defp skip_until_close([], _n), do: {:error, :unexpected_eof}

  # ── motion parsing ──────────────────────────────────────────────────────

  defp parse_frames_header(["Frames: " <> n | rest]) do
    {:ok, String.trim(n) |> String.to_integer(), rest}
  end

  defp parse_frames_header(["Frames:" <> n | rest]) do
    {:ok, String.trim(n) |> String.to_integer(), rest}
  end

  defp parse_frames_header(_), do: {:error, :expected_frames}

  defp parse_frame_time(["Frame Time: " <> t | rest]) do
    {:ok, parse_float(String.trim(t)), rest}
  end

  defp parse_frame_time(["Frame Time:" <> t | rest]) do
    {:ok, parse_float(String.trim(t)), rest}
  end

  defp parse_frame_time(_), do: {:error, :expected_frame_time}

  defp parse_frame_data(lines, frame_count, channel_count) do
    frames =
      lines
      |> Enum.take(frame_count)
      |> Enum.map(fn line ->
        line
        |> String.split()
        |> Enum.map(&parse_float/1)
      end)

    if length(frames) == frame_count and
         Enum.all?(frames, &(length(&1) == channel_count)) do
      {:ok, frames}
    else
      {:error, :frame_data_mismatch}
    end
  end

  # ── helpers ─────────────────────────────────────────────────────────────

  defp expect_keyword([kw | rest], kw), do: {:ok, rest}
  defp expect_keyword(_, kw), do: {:error, {:expected, kw}}

  defp parse_channels(spec) do
    [_count | names] = String.split(spec)
    Enum.map(names, &Map.fetch!(@channel_map, &1))
  end

  defp parse_vec3(text) do
    [x, y, z] =
      text
      |> String.split()
      |> Enum.take(3)
      |> Enum.map(&parse_float/1)

    {x, y, z}
  end

  defp total_channels(joints) do
    Enum.reduce(joints, 0, fn j, acc -> acc + length(j.channels) end)
  end

  defp parse_float(s) do
    s = String.trim(s)

    case Float.parse(s) do
      {f, ""} -> f
      _ -> String.to_integer(s) * 1.0
    end
  end
end
