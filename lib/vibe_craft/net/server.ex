defmodule VibeCraft.Net.Server do
  @moduledoc """
  TCP server for VibeCraft multiplayer.

  Starts a dedicated `VibeCraft.Lobby` and listens for incoming TCP
  connections on the configured port (default `4001`).  Each accepted
  connection is handed off to a `VibeCraft.Net.ConnectionHandler` process.

  Pass `port: 0` to let the OS choose a free ephemeral port; retrieve the
  actual port afterwards with `VibeCraft.Net.Server.port/1`.

  ## Usage

      {:ok, server} = VibeCraft.Net.Server.start_link(port: 4001)
      port          = VibeCraft.Net.Server.port(server)
      lobby         = VibeCraft.Net.Server.lobby(server)

  ## Options

  * `:port` — TCP port to listen on (default `4001`).
  """

  use GenServer

  alias VibeCraft.Lobby
  alias VibeCraft.Net.ConnectionHandler

  @default_port 4001

  @dialyzer {:nowarn_function, [init_server: 1]}

  # ── Client API ─────────────────────────────────────────────────────────────

  @doc "Start the server, optionally linked to the caller."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @doc "Return the TCP port the server is listening on."
  @spec port(GenServer.server()) :: :inet.port_number()
  def port(server) do
    GenServer.call(server, :port)
  end

  @doc "Return the PID of the `Lobby` managed by this server."
  @spec lobby(GenServer.server()) :: pid()
  def lobby(server) do
    GenServer.call(server, :lobby)
  end

  # ── GenServer callbacks ─────────────────────────────────────────────────────

  @impl GenServer
  def init(opts) do
    tcp_port = Keyword.get(opts, :port, @default_port)

    listen_opts = [:binary, packet: :raw, active: false, reuseaddr: true]

    case :gen_tcp.listen(tcp_port, listen_opts) do
      {:ok, listen_socket} -> init_server(listen_socket)
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call(:port, _from, state) do
    {:reply, state.port, state}
  end

  def handle_call(:lobby, _from, state) do
    {:reply, state.lobby, state}
  end

  @impl GenServer
  def terminate(_reason, %{listen_socket: socket}) do
    :gen_tcp.close(socket)
  end

  # ── Private helpers ─────────────────────────────────────────────────────────

  @spec init_server(:inet.socket()) :: {:ok, map()}
  defp init_server(listen_socket) do
    {:ok, lobby} = Lobby.start_link()
    {:ok, actual_port} = :inet.port(listen_socket)
    spawn_link(fn -> accept_loop(listen_socket, lobby) end)
    {:ok, %{listen_socket: listen_socket, lobby: lobby, port: actual_port}}
  end

  @spec accept_loop(:inet.socket(), pid()) :: :ok
  defp accept_loop(listen_socket, lobby) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        ConnectionHandler.start(client_socket, lobby)
        accept_loop(listen_socket, lobby)

      {:error, :closed} ->
        :ok

      {:error, _reason} ->
        accept_loop(listen_socket, lobby)
    end
  end
end
