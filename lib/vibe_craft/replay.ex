defmodule VibeCraft.Replay do
  @moduledoc """
  Replay recording and playback for Phase 3.

  A `Replay` is an append-only log of game events indexed by tick.  The
  engine records events during a live game; later the log can be replayed
  tick by tick to reconstruct the match.

  ## Event tags

  | Tag                 | Fields                                          |
  |---------------------|-------------------------------------------------|
  | `:unit_moved`       | `{unit_id, from_pos, to_pos}`                   |
  | `:unit_attacked`    | `{attacker_id, defender_id, damage}`            |
  | `:unit_spawned`     | `{unit_id, unit_type, player, position}`        |
  | `:unit_died`        | `{unit_id}`                                     |
  | `:spell_cast`       | `{caster_id, spell_name, target_id}`            |
  | `:building_trained` | `{building_id, unit_type}`                      |

  ## Usage

      replay = Replay.new("match-001")
      replay = Replay.record(replay, 0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
      replay = Replay.record(replay, 1, {:unit_moved, 1, {0, 0}, {1, 0}})
      [{1, [_]}] = Replay.events_in_range(replay, 1, 5)
  """

  @type game_id :: String.t()
  @type tick :: non_neg_integer()
  @type event :: tuple()

  @type t :: %__MODULE__{
          game_id: game_id(),
          frames: %{tick() => [event()]},
          duration: non_neg_integer()
        }

  @enforce_keys [:game_id]
  defstruct [:game_id, frames: %{}, duration: 0]

  @doc "Start a new replay log for the game identified by `game_id`."
  @spec new(game_id()) :: t()
  def new(game_id), do: %__MODULE__{game_id: game_id}

  @doc """
  Append `event` to the log at `tick`.

  Multiple events per tick are stored in append order.
  """
  @spec record(t(), tick(), event()) :: t()
  def record(%__MODULE__{frames: frames, duration: dur} = replay, tick, event) do
    existing = Map.get(frames, tick, [])
    new_frames = Map.put(frames, tick, existing ++ [event])
    %{replay | frames: new_frames, duration: max(dur, tick + 1)}
  end

  @doc "Return all events recorded at `tick` (empty list when none)."
  @spec events_at(t(), tick()) :: [event()]
  def events_at(%__MODULE__{frames: frames}, tick) do
    Map.get(frames, tick, [])
  end

  @doc "Return the total number of ticks in the replay (highest tick + 1)."
  @spec duration(t()) :: non_neg_integer()
  def duration(%__MODULE__{duration: d}), do: d

  @doc "Return a sorted list of `{tick, events}` tuples covering the full replay."
  @spec frames(t()) :: [{tick(), [event()]}]
  def frames(%__MODULE__{frames: frames}) do
    Enum.sort_by(frames, fn {tick, _} -> tick end)
  end

  @doc "Return all `{tick, events}` tuples for ticks in the range `first..last` (inclusive)."
  @spec events_in_range(t(), tick(), tick()) :: [{tick(), [event()]}]
  def events_in_range(%__MODULE__{frames: frames}, first, last) do
    frames
    |> Enum.filter(fn {tick, _} -> tick >= first and tick <= last end)
    |> Enum.sort_by(fn {tick, _} -> tick end)
  end
end
