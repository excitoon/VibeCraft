defmodule VibeCraft.ReplayTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Replay

  defp new_replay, do: Replay.new("game-001")

  describe "new/1" do
    test "creates an empty replay with the given game_id" do
      replay = new_replay()
      assert replay.game_id == "game-001"
      assert Replay.duration(replay) == 0
    end
  end

  describe "record/3" do
    test "records an event at a given tick" do
      replay = Replay.record(new_replay(), 0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
      assert [{:unit_spawned, 1, :footman, :player1, {0, 0}}] = Replay.events_at(replay, 0)
    end

    test "appends multiple events at the same tick in order" do
      replay =
        new_replay()
        |> Replay.record(2, {:unit_moved, 1, {0, 0}, {1, 0}})
        |> Replay.record(2, {:unit_attacked, 1, 2, 6})

      events = Replay.events_at(replay, 2)
      assert length(events) == 2
      assert hd(events) == {:unit_moved, 1, {0, 0}, {1, 0}}
    end

    test "returns empty list for ticks with no events" do
      replay = Replay.record(new_replay(), 0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
      assert Replay.events_at(replay, 99) == []
    end

    test "duration reflects the highest recorded tick" do
      replay =
        new_replay()
        |> Replay.record(0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
        |> Replay.record(5, {:unit_died, 1})

      assert Replay.duration(replay) == 6
    end
  end

  describe "frames/1" do
    test "returns frames sorted by tick" do
      replay =
        new_replay()
        |> Replay.record(5, {:unit_died, 2})
        |> Replay.record(0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
        |> Replay.record(2, {:unit_moved, 1, {0, 0}, {1, 0}})

      ticks = Enum.map(Replay.frames(replay), fn {tick, _} -> tick end)
      assert ticks == [0, 2, 5]
    end
  end

  describe "events_in_range/3" do
    test "returns only events within the specified tick range" do
      replay =
        new_replay()
        |> Replay.record(0, {:unit_spawned, 1, :footman, :player1, {0, 0}})
        |> Replay.record(3, {:unit_moved, 1, {0, 0}, {1, 0}})
        |> Replay.record(7, {:unit_died, 1})

      result = Replay.events_in_range(replay, 1, 5)
      assert length(result) == 1
      [{tick, _events}] = result
      assert tick == 3
    end

    test "returns an empty list when no events fall in the range" do
      replay = Replay.record(new_replay(), 10, {:unit_died, 1})
      assert Replay.events_in_range(replay, 0, 5) == []
    end
  end
end
