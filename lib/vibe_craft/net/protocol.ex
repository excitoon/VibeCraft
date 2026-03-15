defmodule VibeCraft.Net.Protocol do
  @moduledoc """
  Wire encoding for VibeCraft network messages.

  Messages are Elixir terms serialised with `:erlang.term_to_binary/1` and
  framed with a 4-byte big-endian length prefix.

  ## Frame layout

      +-----------+-------------------------+
      | len (4 B) | payload (len bytes)     |
      +-----------+-------------------------+

  The `len` value is the byte-length of the *payload* only.
  """

  @header_size 4

  @dialyzer {:nowarn_function, [encode: 1]}

  @doc "Encode `term` as a length-prefixed binary frame."
  @spec encode(term()) :: binary()
  def encode(term) do
    payload = :erlang.term_to_binary(term)
    size = byte_size(payload)
    <<size::unsigned-big-integer-size(32), payload::binary>>
  end

  @doc """
  Decode the next framed message from `buffer`.

  Returns `{:ok, term, rest}` when a complete frame is available, or
  `:incomplete` when more bytes are needed.
  """
  @spec decode(binary()) :: {:ok, term(), binary()} | :incomplete
  def decode(buffer) when byte_size(buffer) < @header_size, do: :incomplete

  def decode(<<size::unsigned-big-integer-size(32), rest::binary>>) do
    if byte_size(rest) >= size do
      <<payload::binary-size(size), remainder::binary>> = rest
      {:ok, :erlang.binary_to_term(payload, [:safe]), remainder}
    else
      :incomplete
    end
  end
end
