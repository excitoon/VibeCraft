defmodule VibeCraft.Net.ProtocolTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Net.Protocol

  describe "encode/1 and decode/1 roundtrip" do
    test "roundtrips a simple atom" do
      term = :ok
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end

    test "roundtrips an ok-tuple" do
      term = {:ok, :start}
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end

    test "roundtrips an error-tuple" do
      term = {:error, :not_registered}
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end

    test "roundtrips a string" do
      term = "hello world"
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end

    test "roundtrips a list of maps" do
      term = [%{id: "abc", max_players: 2}]
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end

    test "roundtrips a command tuple" do
      term = {:register_player, "alice"}
      assert {:ok, ^term, <<>>} = term |> Protocol.encode() |> Protocol.decode()
    end
  end

  describe "decode/1" do
    test "returns :incomplete when buffer is empty" do
      assert :incomplete = Protocol.decode(<<>>)
    end

    test "returns :incomplete when buffer holds only partial header" do
      assert :incomplete = Protocol.decode(<<0, 0>>)
    end

    test "returns :incomplete when payload is truncated" do
      # Encode a term then strip the last byte.
      full = Protocol.encode(:ok)
      truncated = binary_part(full, 0, byte_size(full) - 1)
      assert :incomplete = Protocol.decode(truncated)
    end

    test "returns remainder bytes after the first frame" do
      frame1 = Protocol.encode(:ok)
      frame2 = Protocol.encode(:done)
      combined = frame1 <> frame2

      assert {:ok, :ok, rest} = Protocol.decode(combined)
      assert {:ok, :done, <<>>} = Protocol.decode(rest)
    end

    test "returns :incomplete when a second frame is present but incomplete" do
      frame1 = Protocol.encode(:ok)
      # Build a second frame but only include its header, not the payload.
      payload2 = :erlang.term_to_binary(:done)
      partial_frame2 = <<byte_size(payload2)::unsigned-big-integer-size(32)>>

      assert {:ok, :ok, rest} = Protocol.decode(frame1 <> partial_frame2)
      assert :incomplete = Protocol.decode(rest)
    end
  end
end
