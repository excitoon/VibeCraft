defmodule VibeCraft.Matchmaking do
  @moduledoc """
  Ranked matchmaking and ladder system for Phase 3.

  Manages a queue of players waiting for a rated match and a persistent
  ladder of Elo-style ratings.  When two players are in the queue their
  ratings are compared; if the difference is within the acceptable range a
  match is created automatically.

  ## Ranks

  | Rank        | Rating range |
  |-------------|--------------|
  | `:bronze`   | 0–999        |
  | `:silver`   | 1000–1499    |
  | `:gold`     | 1500–1999    |
  | `:platinum` | 2000–2499    |
  | `:diamond`  | 2500+        |

  ## Usage

      {:ok, mm} = Matchmaking.start_link()
      :ok = Matchmaking.register_player(mm, "alice")
      :ok = Matchmaking.register_player(mm, "bob")
      :ok = Matchmaking.queue_for_match(mm, "alice")
      :ok = Matchmaking.queue_for_match(mm, "bob")
      {:ok, match} = Matchmaking.poll_match(mm, "alice")
      :ok = Matchmaking.report_result(mm, match.id, "alice", :win)
      {:ok, 1_216} = Matchmaking.get_rating(mm, "alice")
  """

  use GenServer

  @type player_id :: String.t()
  @type match_id :: String.t()
  @type rank :: :bronze | :silver | :gold | :platinum | :diamond

  @type player_entry :: %{
          id: player_id(),
          rating: non_neg_integer(),
          wins: non_neg_integer(),
          losses: non_neg_integer()
        }

  @type match :: %{
          id: match_id(),
          player1: player_id(),
          player2: player_id()
        }

  @type state :: %{
          players: %{player_id() => player_entry()},
          queue: [player_id()],
          pending_matches: %{match_id() => match()}
        }

  @initial_rating 1_200
  @elo_k 32
  @max_rating_diff 300

  # ── Client API ────────────────────────────────────────────────────────────

  @doc "Start the matchmaking GenServer."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Register a new player with a default rating of #{@initial_rating}.

  Returns `{:error, :already_registered}` if the player already exists.
  """
  @spec register_player(GenServer.server(), player_id()) :: :ok | {:error, :already_registered}
  def register_player(server, player_id) do
    GenServer.call(server, {:register_player, player_id})
  end

  @doc """
  Add `player_id` to the matchmaking queue.

  When a compatible opponent is already queued a match is created
  automatically.  Returns `{:error, :not_registered}` or
  `{:error, :already_queued}` on failure.
  """
  @spec queue_for_match(GenServer.server(), player_id()) ::
          :ok | {:error, :not_registered | :already_queued}
  def queue_for_match(server, player_id) do
    GenServer.call(server, {:queue_for_match, player_id})
  end

  @doc "Remove `player_id` from the matchmaking queue."
  @spec cancel_queue(GenServer.server(), player_id()) :: :ok | {:error, :not_registered}
  def cancel_queue(server, player_id) do
    GenServer.call(server, {:cancel_queue, player_id})
  end

  @doc """
  Poll for a pending match involving `player_id`.

  Returns `{:ok, match}` when a match is waiting, `{:ok, :waiting}` when
  still in the queue, or `{:error, :not_queued}` otherwise.
  """
  @spec poll_match(GenServer.server(), player_id()) ::
          {:ok, match()} | {:ok, :waiting} | {:error, :not_queued | :not_registered}
  def poll_match(server, player_id) do
    GenServer.call(server, {:poll_match, player_id})
  end

  @doc """
  Report the outcome of `match_id` for `player_id`.

  `result` must be `:win` or `:loss`.  Both players' Elo ratings are
  updated and the match is removed from pending.
  """
  @spec report_result(GenServer.server(), match_id(), player_id(), :win | :loss) ::
          :ok | {:error, :match_not_found | :not_registered}
  def report_result(server, match_id, player_id, result) do
    GenServer.call(server, {:report_result, match_id, player_id, result})
  end

  @doc "Return `{:ok, rating}` for `player_id`."
  @spec get_rating(GenServer.server(), player_id()) ::
          {:ok, non_neg_integer()} | {:error, :not_registered}
  def get_rating(server, player_id) do
    GenServer.call(server, {:get_rating, player_id})
  end

  @doc "Return up to `limit` ladder entries sorted by rating (descending)."
  @spec get_ladder(GenServer.server(), pos_integer()) :: [player_entry()]
  def get_ladder(server, limit \\ 10) do
    GenServer.call(server, {:get_ladder, limit})
  end

  @doc "Return the rank tier that corresponds to `rating`."
  @spec rank_for_rating(non_neg_integer()) :: rank()
  def rank_for_rating(rating) when rating >= 2_500, do: :diamond
  def rank_for_rating(rating) when rating >= 2_000, do: :platinum
  def rank_for_rating(rating) when rating >= 1_500, do: :gold
  def rank_for_rating(rating) when rating >= 1_000, do: :silver
  def rank_for_rating(_rating), do: :bronze

  # ── GenServer callbacks ───────────────────────────────────────────────────

  @impl GenServer
  def init(:ok) do
    {:ok, %{players: %{}, queue: [], pending_matches: %{}}}
  end

  @impl GenServer
  def handle_call({:register_player, player_id}, _from, state) do
    if Map.has_key?(state.players, player_id) do
      {:reply, {:error, :already_registered}, state}
    else
      entry = %{id: player_id, rating: @initial_rating, wins: 0, losses: 0}
      {:reply, :ok, %{state | players: Map.put(state.players, player_id, entry)}}
    end
  end

  def handle_call({:queue_for_match, player_id}, _from, state) do
    cond do
      not Map.has_key?(state.players, player_id) ->
        {:reply, {:error, :not_registered}, state}

      player_id in state.queue ->
        {:reply, {:error, :already_queued}, state}

      true ->
        new_state = try_make_match(%{state | queue: state.queue ++ [player_id]}, player_id)
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:cancel_queue, player_id}, _from, state) do
    if Map.has_key?(state.players, player_id) do
      {:reply, :ok, %{state | queue: List.delete(state.queue, player_id)}}
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  def handle_call({:poll_match, player_id}, _from, state) do
    cond do
      not Map.has_key?(state.players, player_id) ->
        {:reply, {:error, :not_registered}, state}

      player_id in state.queue ->
        {:reply, {:ok, :waiting}, state}

      true ->
        match = find_pending_match(state.pending_matches, player_id)
        {:reply, poll_reply(match), state}
    end
  end

  def handle_call({:report_result, match_id, player_id, result}, _from, state) do
    case Map.get(state.pending_matches, match_id) do
      nil -> {:reply, {:error, :match_not_found}, state}
      match -> apply_match_result(state, match, player_id, result)
    end
  end

  def handle_call({:get_rating, player_id}, _from, state) do
    case Map.get(state.players, player_id) do
      nil -> {:reply, {:error, :not_registered}, state}
      entry -> {:reply, {:ok, entry.rating}, state}
    end
  end

  def handle_call({:get_ladder, limit}, _from, state) do
    ladder =
      state.players
      |> Map.values()
      |> Enum.sort_by(& &1.rating, :desc)
      |> Enum.take(limit)

    {:reply, ladder, state}
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  @spec try_make_match(state(), player_id()) :: state()
  defp try_make_match(%{queue: [_only_one]} = state, _new_player), do: state

  defp try_make_match(%{queue: queue, players: players} = state, new_player) do
    new_rating = players[new_player].rating

    opponent =
      queue
      |> Enum.reject(&(&1 == new_player))
      |> Enum.find(fn pid ->
        abs(players[pid].rating - new_rating) <= @max_rating_diff
      end)

    build_match(state, new_player, opponent)
  end

  @spec build_match(state(), player_id(), player_id() | nil) :: state()
  defp build_match(state, _new_player, nil), do: state

  defp build_match(state, new_player, opponent) do
    match_id = generate_match_id()
    match = %{id: match_id, player1: opponent, player2: new_player}

    %{
      state
      | queue: state.queue |> List.delete(opponent) |> List.delete(new_player),
        pending_matches: Map.put(state.pending_matches, match_id, match)
    }
  end

  @spec find_pending_match(%{match_id() => match()}, player_id()) :: match() | nil
  defp find_pending_match(pending_matches, player_id) do
    Enum.find_value(pending_matches, fn {_id, match} ->
      if match.player1 == player_id or match.player2 == player_id, do: match
    end)
  end

  @spec poll_reply(match() | nil) ::
          {:ok, match()} | {:error, :not_queued}
  defp poll_reply(nil), do: {:error, :not_queued}
  defp poll_reply(match), do: {:ok, match}

  @spec apply_match_result(state(), match(), player_id(), :win | :loss) ::
          {:reply, :ok | {:error, :not_registered}, state()}
  defp apply_match_result(state, match, player_id, result) do
    if Map.has_key?(state.players, player_id) do
      new_state = state |> update_ratings(match, player_id, result) |> remove_match(match.id)
      {:reply, :ok, new_state}
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  @spec update_ratings(state(), match(), player_id(), :win | :loss) :: state()
  defp update_ratings(state, match, reporting_player, result) do
    {winner_id, loser_id} =
      case result do
        :win -> {reporting_player, other_player(match, reporting_player)}
        :loss -> {other_player(match, reporting_player), reporting_player}
      end

    winner = state.players[winner_id]
    loser = state.players[loser_id]
    {w_new, l_new} = elo_update(winner.rating, loser.rating)

    updated_players =
      state.players
      |> Map.put(winner_id, %{winner | rating: w_new, wins: winner.wins + 1})
      |> Map.put(loser_id, %{loser | rating: max(0, l_new), losses: loser.losses + 1})

    %{state | players: updated_players}
  end

  @spec other_player(match(), player_id()) :: player_id()
  defp other_player(%{player1: p1, player2: p2}, player_id) do
    if player_id == p1, do: p2, else: p1
  end

  @spec elo_update(non_neg_integer(), non_neg_integer()) ::
          {non_neg_integer(), integer()}
  defp elo_update(winner_rating, loser_rating) do
    expected_winner = 1.0 / (1.0 + :math.pow(10, (loser_rating - winner_rating) / 400.0))
    expected_loser = 1.0 - expected_winner

    winner_new = round(winner_rating + @elo_k * (1.0 - expected_winner))
    loser_new = round(loser_rating + @elo_k * (0.0 - expected_loser))

    {winner_new, loser_new}
  end

  @spec remove_match(state(), match_id()) :: state()
  defp remove_match(state, match_id) do
    %{state | pending_matches: Map.delete(state.pending_matches, match_id)}
  end

  @spec generate_match_id() :: match_id()
  defp generate_match_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
