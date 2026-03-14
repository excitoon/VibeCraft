defmodule VibeCraft.BuildingTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Building

  describe "new/4" do
    test "creates a town hall with correct stats" do
      b = Building.new(1, :town_hall, :player1, {5, 5})
      assert b.hp == 1_200
      assert b.max_hp == 1_200
      assert b.type == :town_hall
      assert b.player == :player1
      assert b.position == {5, 5}
      assert b.training_queue == []
    end

    test "creates a barracks with correct stats" do
      b = Building.new(1, :barracks, :player2, {3, 3})
      assert b.hp == 800
      assert b.max_hp == 800
      assert b.type == :barracks
    end
  end

  describe "standing?/1" do
    test "returns true when hp > 0" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      assert Building.standing?(b)
    end

    test "returns false when hp == 0" do
      b = %{Building.new(1, :barracks, :player1, {0, 0}) | hp: 0}
      refute Building.standing?(b)
    end
  end

  describe "cost_to_train/1" do
    test "footman costs gold with no lumber" do
      {gold, lumber} = Building.cost_to_train(:footman)
      assert gold > 0
      assert lumber == 0
    end

    test "peasant costs gold with no lumber" do
      {gold, lumber} = Building.cost_to_train(:peasant)
      assert gold > 0
      assert lumber == 0
    end
  end

  describe "can_train/1" do
    test "town hall can train peasants and peons" do
      b = Building.new(1, :town_hall, :player1, {0, 0})
      trainable = Building.can_train(b)
      assert :peasant in trainable
      assert :peon in trainable
    end

    test "barracks can train footmen and grunts" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      trainable = Building.can_train(b)
      assert :footman in trainable
      assert :grunt in trainable
    end
  end

  describe "enqueue_training/2" do
    test "enqueues a valid unit type" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      assert {:ok, updated} = Building.enqueue_training(b, :footman)
      assert length(updated.training_queue) == 1
      assert hd(updated.training_queue).unit_type == :footman
    end

    test "returns error when building cannot train that unit type" do
      b = Building.new(1, :town_hall, :player1, {0, 0})
      assert {:error, :cannot_train} = Building.enqueue_training(b, :footman)
    end

    test "returns error when queue is full" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      {:ok, b} = Building.enqueue_training(b, :footman)
      {:ok, b} = Building.enqueue_training(b, :footman)
      {:ok, b} = Building.enqueue_training(b, :footman)
      {:ok, b} = Building.enqueue_training(b, :footman)
      {:ok, b} = Building.enqueue_training(b, :footman)
      assert {:error, :queue_full} = Building.enqueue_training(b, :footman)
    end
  end

  describe "tick_training/1" do
    test "returns empty list when queue is empty" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      assert {^b, []} = Building.tick_training(b)
    end

    test "decrements ticks_remaining on front entry" do
      {:ok, b} =
        Building.new(1, :barracks, :player1, {0, 0})
        |> Building.enqueue_training(:footman)

      {updated, trained} = Building.tick_training(b)
      assert trained == []
      assert hd(updated.training_queue).ticks_remaining == 59
    end

    test "removes entry and returns unit_type when training completes" do
      b = Building.new(1, :barracks, :player1, {0, 0})
      # Force ticks_remaining to 1 so it finishes next tick.
      b = %{b | training_queue: [%{unit_type: :footman, ticks_remaining: 1}]}
      {updated, trained} = Building.tick_training(b)
      assert trained == [:footman]
      assert updated.training_queue == []
    end
  end
end
