defmodule VibeCraft.Net.ServerClientTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Net.{Client, Server}

  # Start a fresh server on an OS-assigned port before each test.
  setup do
    {:ok, server} = Server.start_link(port: 0)
    port = Server.port(server)
    {:ok, client} = Client.connect("localhost", port)
    on_exit(fn -> Client.disconnect(client) end)
    %{client: client}
  end

  describe "register_player/2 over TCP" do
    test "registers a new player successfully", %{client: client} do
      assert :ok = Client.register_player(client, "alice")
    end

    test "returns error when player is already registered", %{client: client} do
      :ok = Client.register_player(client, "alice")
      assert {:error, :already_registered} = Client.register_player(client, "alice")
    end
  end

  describe "create_room/3 over TCP" do
    test "creates a room and returns its id", %{client: client} do
      :ok = Client.register_player(client, "alice")
      assert {:ok, room_id} = Client.create_room(client, "alice")
      assert is_binary(room_id)
    end

    test "returns error when player is not registered", %{client: client} do
      assert {:error, :not_registered} = Client.create_room(client, "ghost")
    end
  end

  describe "join_room/3 over TCP" do
    setup %{client: client} do
      :ok = Client.register_player(client, "alice")
      :ok = Client.register_player(client, "bob")
      {:ok, room_id} = Client.create_room(client, "alice")
      %{room_id: room_id}
    end

    test "joins an existing room", %{client: client, room_id: room_id} do
      assert :ok = Client.join_room(client, "bob", room_id)
    end

    test "returns error for unknown room", %{client: client} do
      assert {:error, :room_not_found} = Client.join_room(client, "bob", "no-such-room")
    end

    test "returns error when room is full", %{client: client, room_id: room_id} do
      :ok = Client.join_room(client, "bob", room_id)
      :ok = Client.register_player(client, "carol")
      assert {:error, :room_full} = Client.join_room(client, "carol", room_id)
    end
  end

  describe "set_ready/3 and room_status/2 over TCP" do
    setup %{client: client} do
      :ok = Client.register_player(client, "alice")
      :ok = Client.register_player(client, "bob")
      {:ok, room_id} = Client.create_room(client, "alice")
      :ok = Client.join_room(client, "bob", room_id)
      %{room_id: room_id}
    end

    test "room is :waiting until all players are ready", %{client: client, room_id: room_id} do
      assert {:ok, :waiting} = Client.room_status(client, room_id)
    end

    test "room transitions to :start when all players are ready",
         %{client: client, room_id: room_id} do
      :ok = Client.set_ready(client, "alice", true)
      :ok = Client.set_ready(client, "bob", true)
      assert {:ok, :start} = Client.room_status(client, room_id)
    end

    test "room returns to :waiting when a player un-readies",
         %{client: client, room_id: room_id} do
      :ok = Client.set_ready(client, "alice", true)
      :ok = Client.set_ready(client, "bob", true)
      :ok = Client.set_ready(client, "alice", false)
      assert {:ok, :waiting} = Client.room_status(client, room_id)
    end
  end

  describe "list_rooms/1 over TCP" do
    test "returns empty list when no rooms exist", %{client: client} do
      assert Client.list_rooms(client) == []
    end

    test "returns room info after creation", %{client: client} do
      :ok = Client.register_player(client, "alice")
      {:ok, room_id} = Client.create_room(client, "alice")
      rooms = Client.list_rooms(client)
      assert length(rooms) == 1
      assert hd(rooms).id == room_id
    end
  end

  describe "two independent clients on the same server" do
    test "each client sees the shared lobby state" do
      {:ok, server} = Server.start_link(port: 0)
      port = Server.port(server)

      {:ok, c1} = Client.connect("localhost", port)
      {:ok, c2} = Client.connect("localhost", port)

      on_exit(fn ->
        Client.disconnect(c1)
        Client.disconnect(c2)
        GenServer.stop(server)
      end)

      :ok = Client.register_player(c1, "player1")
      {:ok, room_id} = Client.create_room(c1, "player1")

      :ok = Client.register_player(c2, "player2")
      assert :ok = Client.join_room(c2, "player2", room_id)

      rooms = Client.list_rooms(c1)
      assert Enum.any?(rooms, &(&1.id == room_id))
    end
  end
end
