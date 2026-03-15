defmodule VibeCraft.Net.Client do
  @moduledoc """
  TCP client for the VibeCraft multiplayer server.

  Provides the same lobby API as `VibeCraft.Lobby` but communicates over a
  TCP connection to a remote `VibeCraft.Net.Server`.  Each call encodes the
  command with `VibeCraft.Net.Protocol`, sends it, and synchronously waits
  for the length-prefixed reply.

  ## Usage

      {:ok, client} = VibeCraft.Net.Client.connect("localhost", 4001)

      :ok           = VibeCraft.Net.Client.register_player(client, "alice")
      {:ok, room}   = VibeCraft.Net.Client.create_room(client, "alice")

      :ok           = VibeCraft.Net.Client.disconnect(client)

  ## Error handling

  Network errors are surfaced as `{:error, reason}` tuples so callers can
  distinguish transport failures from logical lobby errors.
  """

  use GenServer

  alias VibeCraft.Net.Protocol

  @dialyzer {:nowarn_function, connect: 3, rpc: 2, fetch_and_decode: 2}

  @type t :: GenServer.server()

  # ── Client API ─────────────────────────────────────────────────────────────

  @doc """
  Connect to a VibeCraft server at `host:port` and return a client PID.

  `host` may be a string hostname or an `:inet.ip_address()` tuple.
  Pass GenServer options (e.g. `name:`) via `opts`.
  """
  @spec connect(String.t() | :inet.ip_address(), :inet.port_number(), keyword()) ::
          {:ok, t()} | :ignore | {:error, term()}
  def connect(host, port, opts \\ []) do
    GenServer.start_link(__MODULE__, {host, port}, opts)
  end

  @doc "Close the TCP connection and stop the client process."
  @spec disconnect(t()) :: :ok
  def disconnect(client) do
    GenServer.stop(client)
  end

  @doc "Register `player_id` with the server lobby."
  @spec register_player(t(), String.t()) :: :ok | {:error, term()}
  def register_player(client, player_id) do
    rpc(client, {:register_player, player_id})
  end

  @doc "Create a new room owned by `player_id`."
  @spec create_room(t(), String.t(), pos_integer()) :: {:ok, String.t()} | {:error, term()}
  def create_room(client, player_id, max_players \\ 2) do
    rpc(client, {:create_room, player_id, max_players})
  end

  @doc "Join an existing room identified by `room_id`."
  @spec join_room(t(), String.t(), String.t()) :: :ok | {:error, term()}
  def join_room(client, player_id, room_id) do
    rpc(client, {:join_room, player_id, room_id})
  end

  @doc "Toggle the ready flag for `player_id`."
  @spec set_ready(t(), String.t(), boolean()) :: :ok | {:error, term()}
  def set_ready(client, player_id, ready?) do
    rpc(client, {:set_ready, player_id, ready?})
  end

  @doc "Return the current status of `room_id`."
  @spec room_status(t(), String.t()) :: {:ok, atom()} | {:error, term()}
  def room_status(client, room_id) do
    rpc(client, {:room_status, room_id})
  end

  @doc "List all current rooms on the server."
  @spec list_rooms(t()) :: [map()]
  def list_rooms(client) do
    rpc(client, :list_rooms)
  end

  # ── GenServer callbacks ─────────────────────────────────────────────────────

  @impl GenServer
  def init({host, port}) do
    connect_opts = [:binary, packet: :raw, active: false]

    case :gen_tcp.connect(to_charlist(host), port, connect_opts) do
      {:ok, socket} -> {:ok, %{socket: socket, buffer: <<>>}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:rpc, command}, _from, state) do
    with :ok <- :gen_tcp.send(state.socket, Protocol.encode(command)),
         {:ok, reply, new_buffer} <- recv_reply(state.socket, state.buffer) do
      {:reply, reply, %{state | buffer: new_buffer}}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def terminate(_reason, %{socket: socket}) do
    :gen_tcp.close(socket)
  end

  # ── Private helpers ─────────────────────────────────────────────────────────

  @spec rpc(t(), term()) :: term()
  defp rpc(client, command) do
    GenServer.call(client, {:rpc, command})
  end

  @spec recv_reply(:inet.socket(), binary()) :: {:ok, term(), binary()} | {:error, term()}
  defp recv_reply(socket, buffer) do
    case Protocol.decode(buffer) do
      {:ok, term, rest} -> {:ok, term, rest}
      :incomplete -> fetch_and_decode(socket, buffer)
    end
  end

  @spec fetch_and_decode(:inet.socket(), binary()) :: {:ok, term(), binary()} | {:error, term()}
  defp fetch_and_decode(socket, buffer) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> recv_reply(socket, buffer <> data)
      {:error, reason} -> {:error, reason}
    end
  end
end
