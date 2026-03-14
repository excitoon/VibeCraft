defmodule VibeCraft.Net.ConnectionHandler do
  @moduledoc """
  Per-connection TCP handler for the VibeCraft server.

  One `ConnectionHandler` process is spawned for every accepted TCP
  connection.  It reads length-prefixed frames from the socket using
  `VibeCraft.Net.Protocol`, dispatches each command to the shared
  `VibeCraft.Lobby`, and writes back the reply.

  The process is not linked to the accept loop so that an individual
  connection crash does not bring down the whole server.

  ## Supported commands

  | Command tuple                              | Lobby function called          |
  |--------------------------------------------|--------------------------------|
  | `{:register_player, player_id}`            | `Lobby.register_player/2`      |
  | `{:create_room, player_id, max_players}`   | `Lobby.create_room/3`          |
  | `{:join_room, player_id, room_id}`         | `Lobby.join_room/3`            |
  | `{:set_ready, player_id, ready?}`          | `Lobby.set_ready/3`            |
  | `{:room_status, room_id}`                  | `Lobby.room_status/2`          |
  | `:list_rooms`                              | `Lobby.list_rooms/1`           |
  """

  alias VibeCraft.Lobby
  alias VibeCraft.Net.Protocol

  @doc """
  Spawn a handler process for `socket` and transfer socket ownership to it.

  Returns `{:ok, pid}`.
  """
  @spec start(:inet.socket(), pid()) :: {:ok, pid()}
  def start(socket, lobby) do
    pid = spawn(fn -> loop(socket, lobby, <<>>) end)
    :gen_tcp.controlling_process(socket, pid)
    {:ok, pid}
  end

  # ── Private helpers ───────────────────────────────────────────────────────

  @spec loop(:inet.socket(), pid(), binary()) :: :ok
  defp loop(socket, lobby, buffer) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> handle_data(socket, lobby, buffer <> data)
      {:error, _reason} -> :ok
    end
  end

  @spec handle_data(:inet.socket(), pid(), binary()) :: :ok
  defp handle_data(socket, lobby, buffer) do
    case Protocol.decode(buffer) do
      {:ok, command, rest} ->
        reply = dispatch(lobby, command)
        :gen_tcp.send(socket, Protocol.encode(reply))
        handle_data(socket, lobby, rest)

      :incomplete ->
        loop(socket, lobby, buffer)
    end
  end

  @spec dispatch(pid(), term()) :: term()
  defp dispatch(lobby, {:register_player, player_id}) do
    Lobby.register_player(lobby, player_id)
  end

  defp dispatch(lobby, {:create_room, player_id, max_players}) do
    Lobby.create_room(lobby, player_id, max_players)
  end

  defp dispatch(lobby, {:join_room, player_id, room_id}) do
    Lobby.join_room(lobby, player_id, room_id)
  end

  defp dispatch(lobby, {:set_ready, player_id, ready?}) do
    Lobby.set_ready(lobby, player_id, ready?)
  end

  defp dispatch(lobby, {:room_status, room_id}) do
    Lobby.room_status(lobby, room_id)
  end

  defp dispatch(lobby, :list_rooms) do
    Lobby.list_rooms(lobby)
  end

  defp dispatch(_lobby, _unknown) do
    {:error, :unknown_command}
  end
end
