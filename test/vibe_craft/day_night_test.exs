defmodule VibeCraft.DayNightTest do
  use ExUnit.Case, async: true

  alias VibeCraft.DayNight

  describe "new/1" do
    test "starts at tick 0" do
      cycle = DayNight.new()
      assert cycle.tick == 0
    end

    test "accepts a custom cycle length" do
      cycle = DayNight.new(120)
      assert cycle.cycle_length == 120
    end
  end

  describe "tick/1" do
    test "advances tick by one" do
      cycle = DayNight.new()
      assert DayNight.tick(cycle).tick == 1
    end

    test "wraps back to 0 at end of cycle" do
      cycle = %{DayNight.new(4) | tick: 3}
      assert DayNight.tick(cycle).tick == 0
    end
  end

  describe "phase/1" do
    test "tick 0 is :dawn" do
      assert DayNight.phase(DayNight.new(600)) == :dawn
    end

    test "tick at 25% is :day" do
      cycle = %{DayNight.new(600) | tick: 150}
      assert DayNight.phase(cycle) == :day
    end

    test "tick at 75% is :dusk" do
      cycle = %{DayNight.new(600) | tick: 450}
      assert DayNight.phase(cycle) == :dusk
    end

    test "tick at 88% is :night" do
      cycle = %{DayNight.new(600) | tick: 525}
      assert DayNight.phase(cycle) == :night
    end
  end

  describe "ambient_color/1" do
    test "dawn yields a warm orange tint" do
      cycle = DayNight.new(600)
      {r, g, b} = DayNight.ambient_color(cycle)
      assert r == 1.0
      assert g < 1.0
      assert b < g
    end

    test "day yields full white light" do
      cycle = %{DayNight.new(600) | tick: 200}
      assert DayNight.ambient_color(cycle) == {1.0, 1.0, 1.0}
    end

    test "night yields a dark blue tint" do
      cycle = %{DayNight.new(600) | tick: 540}
      {r, _g, b} = DayNight.ambient_color(cycle)
      assert b > r
    end
  end
end
