defmodule VibeCraft.Campaign.MissionTest do
  use ExUnit.Case, async: true

  # Define a minimal mission module inline for testing.
  defmodule SampleMission do
    use VibeCraft.Campaign.Mission

    mission_name("Storm the Gates")

    objective(:destroy_all_enemies)
    objective(:survive_20_ticks)
  end

  # A mission that overrides all callbacks.
  defmodule CustomCallbackMission do
    use VibeCraft.Campaign.Mission

    mission_name("Custom Callbacks")

    objective(:collect_500_gold)

    @impl VibeCraft.Campaign.Mission
    def on_start(game), do: Map.put(game, :started, true)

    @impl VibeCraft.Campaign.Mission
    def on_tick(game, tick), do: Map.put(game, :last_tick, tick)

    @impl VibeCraft.Campaign.Mission
    def on_victory(game), do: Map.put(game, :victory, true)
  end

  describe "mission_name/1 macro" do
    test "sets the mission name" do
      assert SampleMission.name() == "Storm the Gates"
    end
  end

  describe "objective/1 macro" do
    test "accumulates objectives in declaration order" do
      assert SampleMission.objectives() == [:destroy_all_enemies, :survive_20_ticks]
    end

    test "single objective is returned as a one-element list" do
      assert CustomCallbackMission.objectives() == [:collect_500_gold]
    end
  end

  describe "default callbacks" do
    test "on_start/1 returns the game unchanged by default" do
      game = %{tick: 0}
      assert SampleMission.on_start(game) == game
    end

    test "on_tick/2 returns the game unchanged by default" do
      game = %{tick: 5}
      assert SampleMission.on_tick(game, 5) == game
    end

    test "on_victory/1 returns the game unchanged by default" do
      game = %{tick: 10}
      assert SampleMission.on_victory(game) == game
    end
  end

  describe "overridden callbacks" do
    test "on_start/1 can mutate game state" do
      result = CustomCallbackMission.on_start(%{})
      assert result[:started] == true
    end

    test "on_tick/2 receives the tick number" do
      result = CustomCallbackMission.on_tick(%{}, 42)
      assert result[:last_tick] == 42
    end

    test "on_victory/1 can mutate game state" do
      result = CustomCallbackMission.on_victory(%{})
      assert result[:victory] == true
    end
  end

  describe "behaviour conformance" do
    test "SampleMission implements the Mission behaviour" do
      assert function_exported?(SampleMission, :name, 0)
      assert function_exported?(SampleMission, :objectives, 0)
      assert function_exported?(SampleMission, :on_start, 1)
      assert function_exported?(SampleMission, :on_tick, 2)
      assert function_exported?(SampleMission, :on_victory, 1)
    end
  end
end
