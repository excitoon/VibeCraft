defmodule VibeCraft.LobbyTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Lobby

  setup do
    {:ok, lobby} = Lobby.start_link()
    %{lobby: lobby}
  end

  describe "register_player/2" do
    test "registers a new player successfully", %{lobby: lobby} do
      assert :ok = Lobby.register_player(lobby, "alice")
    end

    test "returns error when player is already registered", %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      assert {:error, :already_registered} = Lobby.register_player(lobby, "alice")
    end
  end

  describe "create_room/3" do
    test "creates a room and returns its id", %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      assert {:ok, room_id} = Lobby.create_room(lobby, "alice")
      assert is_binary(room_id)
    end

    test "returns error when player is not registered", %{lobby: lobby} do
      assert {:error, :not_registered} = Lobby.create_room(lobby, "ghost")
    end

    test "returns error when player is already in a room", %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      {:ok, _room_id} = Lobby.create_room(lobby, "alice")
      assert {:error, :already_in_room} = Lobby.create_room(lobby, "alice")
    end
  end

  describe "join_room/3" do
    setup %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      :ok = Lobby.register_player(lobby, "bob")
      {:ok, room_id} = Lobby.create_room(lobby, "alice")
      %{room_id: room_id}
    end

    test "joins an existing room", %{lobby: lobby, room_id: room_id} do
      assert :ok = Lobby.join_room(lobby, "bob", room_id)
    end

    test "returns error for unknown room", %{lobby: lobby} do
      assert {:error, :room_not_found} = Lobby.join_room(lobby, "bob", "no-such-room")
    end

    test "returns error when player is not registered", %{lobby: lobby, room_id: room_id} do
      assert {:error, :not_registered} = Lobby.join_room(lobby, "ghost", room_id)
    end

    test "returns error when player is already in a room", %{lobby: lobby, room_id: room_id} do
      :ok = Lobby.join_room(lobby, "bob", room_id)
      assert {:error, :already_in_room} = Lobby.join_room(lobby, "bob", room_id)
    end

    test "returns error when room is full", %{lobby: lobby, room_id: room_id} do
      # Room was created with default max_players: 2. Alice is already in.
      :ok = Lobby.join_room(lobby, "bob", room_id)
      :ok = Lobby.register_player(lobby, "carol")
      assert {:error, :room_full} = Lobby.join_room(lobby, "carol", room_id)
    end
  end

  describe "set_ready/3" do
    setup %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      :ok = Lobby.register_player(lobby, "bob")
      {:ok, room_id} = Lobby.create_room(lobby, "alice")
      :ok = Lobby.join_room(lobby, "bob", room_id)
      %{room_id: room_id}
    end

    test "marks a player as ready", %{lobby: lobby} do
      assert :ok = Lobby.set_ready(lobby, "alice", true)
    end

    test "marks a player as not ready", %{lobby: lobby} do
      :ok = Lobby.set_ready(lobby, "alice", true)
      assert :ok = Lobby.set_ready(lobby, "alice", false)
    end

    test "returns error for unregistered player", %{lobby: lobby} do
      assert {:error, :not_registered} = Lobby.set_ready(lobby, "ghost", true)
    end

    test "returns error when player has no room", %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "solo")
      assert {:error, :not_in_room} = Lobby.set_ready(lobby, "solo", true)
    end
  end

  describe "room_status/2" do
    setup %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      :ok = Lobby.register_player(lobby, "bob")
      {:ok, room_id} = Lobby.create_room(lobby, "alice")
      :ok = Lobby.join_room(lobby, "bob", room_id)
      %{room_id: room_id}
    end

    test "returns :waiting when not all players are ready", %{lobby: lobby, room_id: room_id} do
      assert {:ok, :waiting} = Lobby.room_status(lobby, room_id)
    end

    test "returns :start when all players are ready and room is at capacity",
         %{lobby: lobby, room_id: room_id} do
      :ok = Lobby.set_ready(lobby, "alice", true)
      :ok = Lobby.set_ready(lobby, "bob", true)
      assert {:ok, :start} = Lobby.room_status(lobby, room_id)
    end

    test "returns :waiting when only some players are ready",
         %{lobby: lobby, room_id: room_id} do
      :ok = Lobby.set_ready(lobby, "alice", true)
      assert {:ok, :waiting} = Lobby.room_status(lobby, room_id)
    end

    test "returns error for unknown room", %{lobby: lobby} do
      assert {:error, :room_not_found} = Lobby.room_status(lobby, "no-such-room")
    end
  end

  describe "list_rooms/1" do
    test "returns an empty list when no rooms exist", %{lobby: lobby} do
      assert Lobby.list_rooms(lobby) == []
    end

    test "returns room info after creation", %{lobby: lobby} do
      :ok = Lobby.register_player(lobby, "alice")
      {:ok, room_id} = Lobby.create_room(lobby, "alice")
      rooms = Lobby.list_rooms(lobby)
      assert length(rooms) == 1
      assert hd(rooms).id == room_id
    end
  end
end
