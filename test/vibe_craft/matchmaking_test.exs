defmodule VibeCraft.MatchmakingTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Matchmaking

  setup do
    {:ok, mm} = Matchmaking.start_link()
    %{mm: mm}
  end

  defp register(mm, ids) do
    Enum.each(ids, &Matchmaking.register_player(mm, &1))
  end

  describe "register_player/2" do
    test "registers a new player", %{mm: mm} do
      assert :ok = Matchmaking.register_player(mm, "alice")
    end

    test "returns error for duplicate registration", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      assert {:error, :already_registered} = Matchmaking.register_player(mm, "alice")
    end
  end

  describe "queue_for_match/2" do
    test "queues a registered player", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      assert :ok = Matchmaking.queue_for_match(mm, "alice")
    end

    test "returns error for unregistered player", %{mm: mm} do
      assert {:error, :not_registered} = Matchmaking.queue_for_match(mm, "ghost")
    end

    test "returns error when player is already queued", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "alice")
      assert {:error, :already_queued} = Matchmaking.queue_for_match(mm, "alice")
    end

    test "creates a match when two compatible players queue", %{mm: mm} do
      register(mm, ["alice", "bob"])
      :ok = Matchmaking.queue_for_match(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "bob")
      assert {:ok, %{player1: _, player2: _}} = Matchmaking.poll_match(mm, "alice")
    end
  end

  describe "cancel_queue/2" do
    test "removes player from queue", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "alice")
      assert :ok = Matchmaking.cancel_queue(mm, "alice")
      assert {:error, :not_queued} = Matchmaking.poll_match(mm, "alice")
    end

    test "returns error for unregistered player", %{mm: mm} do
      assert {:error, :not_registered} = Matchmaking.cancel_queue(mm, "ghost")
    end
  end

  describe "poll_match/2" do
    test "returns :waiting while player is in queue", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "alice")
      assert {:ok, :waiting} = Matchmaking.poll_match(mm, "alice")
    end

    test "returns error for unregistered player", %{mm: mm} do
      assert {:error, :not_registered} = Matchmaking.poll_match(mm, "ghost")
    end
  end

  describe "report_result/4" do
    setup %{mm: mm} do
      register(mm, ["alice", "bob"])
      :ok = Matchmaking.queue_for_match(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "bob")
      {:ok, match} = Matchmaking.poll_match(mm, "alice")
      %{match: match}
    end

    test "updating rating after a win", %{mm: mm, match: match} do
      {:ok, before_rating} = Matchmaking.get_rating(mm, "alice")
      :ok = Matchmaking.report_result(mm, match.id, "alice", :win)
      {:ok, after_rating} = Matchmaking.get_rating(mm, "alice")
      assert after_rating > before_rating
    end

    test "updating rating after a loss", %{mm: mm, match: match} do
      {:ok, before_rating} = Matchmaking.get_rating(mm, "bob")
      :ok = Matchmaking.report_result(mm, match.id, "bob", :loss)
      {:ok, after_rating} = Matchmaking.get_rating(mm, "bob")
      assert after_rating < before_rating
    end

    test "returns error for unknown match", %{mm: mm} do
      assert {:error, :match_not_found} =
               Matchmaking.report_result(mm, "no-such-match", "alice", :win)
    end

    test "returns error for unregistered player", %{mm: mm, match: match} do
      assert {:error, :not_registered} =
               Matchmaking.report_result(mm, match.id, "ghost", :win)
    end
  end

  describe "get_rating/2" do
    test "returns initial rating for a new player", %{mm: mm} do
      :ok = Matchmaking.register_player(mm, "alice")
      assert {:ok, 1_200} = Matchmaking.get_rating(mm, "alice")
    end

    test "returns error for unregistered player", %{mm: mm} do
      assert {:error, :not_registered} = Matchmaking.get_rating(mm, "ghost")
    end
  end

  describe "get_ladder/2" do
    test "returns players sorted by rating descending", %{mm: mm} do
      register(mm, ["alice", "bob"])
      ladder = Matchmaking.get_ladder(mm, 10)
      ratings = Enum.map(ladder, & &1.rating)
      assert ratings == Enum.sort(ratings, :desc)
    end

    test "limits the number of returned entries", %{mm: mm} do
      Enum.each(1..5, fn i -> Matchmaking.register_player(mm, "player_#{i}") end)
      assert length(Matchmaking.get_ladder(mm, 3)) == 3
    end
  end

  describe "rank_for_rating/1" do
    test ":bronze for rating below 1000" do
      assert Matchmaking.rank_for_rating(999) == :bronze
    end

    test ":silver for rating 1000" do
      assert Matchmaking.rank_for_rating(1_000) == :silver
    end

    test ":gold for rating 1500" do
      assert Matchmaking.rank_for_rating(1_500) == :gold
    end

    test ":platinum for rating 2000" do
      assert Matchmaking.rank_for_rating(2_000) == :platinum
    end

    test ":diamond for rating 2500 and above" do
      assert Matchmaking.rank_for_rating(2_500) == :diamond
      assert Matchmaking.rank_for_rating(3_000) == :diamond
    end
  end
end
