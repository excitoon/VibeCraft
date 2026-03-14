defmodule VibeCraft.Lobby do
  @moduledoc """
  Multiplayer lobby GenServer for Phase 2.

  The lobby manages player registration, room creation, and the ready-up
  handshake before a game session starts.  It is designed for local BEAM
  distribution or raw TCP clients that talk to a proxy; the GenServer
  itself is transport-agnostic.

  ## Lifecycle

      {:ok, lobby} = VibeCraft.Lobby.start_link()

      :ok = VibeCraft.Lobby.register_player(lobby, "alice")
      :ok = VibeCraft.Lobby.register_player(lobby, "bob")

      {:ok, room_id} = VibeCraft.Lobby.create_room(lobby, "alice")
      :ok            = VibeCraft.Lobby.join_room(lobby, "bob", room_id)

      :ok            = VibeCraft.Lobby.set_ready(lobby, "alice", true)
      :ok            = VibeCraft.Lobby.set_ready(lobby, "bob",   true)

      {:ok, :start}  = VibeCraft.Lobby.room_status(lobby, room_id)

  ## Error atoms

  | Atom                   | Meaning                                   |
  |------------------------|-------------------------------------------|
  | `:not_registered`      | Player ID unknown to this lobby           |
  | `:already_registered`  | Player ID already exists                  |
  | `:room_not_found`      | Room ID does not exist                    |
  | `:already_in_room`     | Player is already in a room               |
  | `:room_full`           | Room has reached its `max_players` limit  |
  | `:not_in_room`         | Player is not in the referenced room      |
  """

  use GenServer

  @type player_id :: String.t()
  @type room_id :: String.t()
  @type player_status :: :waiting | :ready
  @type room_status :: :waiting | :start

  @type room :: %{
          id: room_id(),
          players: %{player_id() => player_status()},
          max_players: pos_integer()
        }

  @type state :: %{
          rooms: %{room_id() => room()},
          player_rooms: %{player_id() => room_id()},
          registered: MapSet.t()
        }

  # ── Client API ────────────────────────────────────────────────────────────

  @doc "Start a lobby GenServer, optionally linked to the caller."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Register `player_id` with the lobby.

  Returns `:ok` on success, or `{:error, :already_registered}` if the
  player is already known.
  """
  @spec register_player(GenServer.server(), player_id()) :: :ok | {:error, :already_registered}
  def register_player(server, player_id) do
    GenServer.call(server, {:register_player, player_id})
  end

  @doc """
  Create a new room owned by `player_id`.

  Returns `{:ok, room_id}` on success.  Errors:
  - `{:error, :not_registered}` — player not known to this lobby
  - `{:error, :already_in_room}` — player is already in a room
  """
  @spec create_room(GenServer.server(), player_id(), pos_integer()) ::
          {:ok, room_id()} | {:error, :not_registered | :already_in_room}
  def create_room(server, player_id, max_players \\ 2) do
    GenServer.call(server, {:create_room, player_id, max_players})
  end

  @doc """
  Join an existing room.

  Returns `:ok` on success.  Errors:
  - `{:error, :not_registered}` — player not known
  - `{:error, :already_in_room}` — player already in a room
  - `{:error, :room_not_found}` — room does not exist
  - `{:error, :room_full}` — room has no free slots
  """
  @spec join_room(GenServer.server(), player_id(), room_id()) ::
          :ok | {:error, :not_registered | :already_in_room | :room_not_found | :room_full}
  def join_room(server, player_id, room_id) do
    GenServer.call(server, {:join_room, player_id, room_id})
  end

  @doc """
  Toggle the ready flag for `player_id`.

  Returns `:ok` on success.  Errors:
  - `{:error, :not_registered}` — player not known
  - `{:error, :not_in_room}` — player has not joined any room
  """
  @spec set_ready(GenServer.server(), player_id(), boolean()) ::
          :ok | {:error, :not_registered | :not_in_room}
  def set_ready(server, player_id, ready?) do
    GenServer.call(server, {:set_ready, player_id, ready?})
  end

  @doc """
  Return the current status of `room_id`.

  Returns `{:ok, :start}` when all players are ready and the room is at
  capacity, `{:ok, :waiting}` otherwise.  Returns
  `{:error, :room_not_found}` for an unknown room.
  """
  @spec room_status(GenServer.server(), room_id()) ::
          {:ok, room_status()} | {:error, :room_not_found}
  def room_status(server, room_id) do
    GenServer.call(server, {:room_status, room_id})
  end

  @doc """
  List all current rooms with their player counts and status.

  Returns a list of maps with keys `:id`, `:players`, `:max_players`.
  """
  @spec list_rooms(GenServer.server()) :: [map()]
  def list_rooms(server) do
    GenServer.call(server, :list_rooms)
  end

  # ── GenServer callbacks ───────────────────────────────────────────────────

  @impl GenServer
  def init(:ok) do
    {:ok, %{rooms: %{}, player_rooms: %{}, registered: MapSet.new()}}
  end

  @impl GenServer
  def handle_call({:register_player, player_id}, _from, state) do
    if MapSet.member?(state.registered, player_id) do
      {:reply, {:error, :already_registered}, state}
    else
      {:reply, :ok, %{state | registered: MapSet.put(state.registered, player_id)}}
    end
  end

  def handle_call({:create_room, player_id, max_players}, _from, state) do
    cond do
      not MapSet.member?(state.registered, player_id) ->
        {:reply, {:error, :not_registered}, state}

      Map.has_key?(state.player_rooms, player_id) ->
        {:reply, {:error, :already_in_room}, state}

      true ->
        room_id = generate_room_id()
        room = %{id: room_id, players: %{player_id => :waiting}, max_players: max_players}
        new_state = put_player_in_room(state, player_id, room_id, room)
        {:reply, {:ok, room_id}, new_state}
    end
  end

  def handle_call({:join_room, player_id, room_id}, _from, state) do
    cond do
      not MapSet.member?(state.registered, player_id) ->
        {:reply, {:error, :not_registered}, state}

      Map.has_key?(state.player_rooms, player_id) ->
        {:reply, {:error, :already_in_room}, state}

      not Map.has_key?(state.rooms, room_id) ->
        {:reply, {:error, :room_not_found}, state}

      map_size(state.rooms[room_id].players) >= state.rooms[room_id].max_players ->
        {:reply, {:error, :room_full}, state}

      true ->
        room = state.rooms[room_id]
        updated_room = %{room | players: Map.put(room.players, player_id, :waiting)}
        new_state = put_player_in_room(state, player_id, room_id, updated_room)
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:set_ready, player_id, ready?}, _from, state) do
    cond do
      not MapSet.member?(state.registered, player_id) ->
        {:reply, {:error, :not_registered}, state}

      not Map.has_key?(state.player_rooms, player_id) ->
        {:reply, {:error, :not_in_room}, state}

      true ->
        room_id = state.player_rooms[player_id]
        status = if ready?, do: :ready, else: :waiting
        room = state.rooms[room_id]
        updated_room = %{room | players: Map.put(room.players, player_id, status)}
        new_state = %{state | rooms: Map.put(state.rooms, room_id, updated_room)}
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:room_status, room_id}, _from, state) do
    case Map.get(state.rooms, room_id) do
      nil ->
        {:reply, {:error, :room_not_found}, state}

      room ->
        status = compute_room_status(room)
        {:reply, {:ok, status}, state}
    end
  end

  def handle_call(:list_rooms, _from, state) do
    rooms =
      state.rooms
      |> Map.values()
      |> Enum.map(fn room ->
        %{id: room.id, players: room.players, max_players: room.max_players}
      end)

    {:reply, rooms, state}
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  @spec generate_room_id() :: room_id()
  defp generate_room_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  @spec put_player_in_room(state(), player_id(), room_id(), room()) :: state()
  defp put_player_in_room(state, player_id, room_id, room) do
    %{
      state
      | rooms: Map.put(state.rooms, room_id, room),
        player_rooms: Map.put(state.player_rooms, player_id, room_id)
    }
  end

  @spec compute_room_status(room()) :: room_status()
  defp compute_room_status(%{players: players, max_players: max_players}) do
    player_count = map_size(players)
    all_ready = Enum.all?(players, fn {_id, status} -> status == :ready end)

    if player_count >= max_players and all_ready, do: :start, else: :waiting
  end
end
