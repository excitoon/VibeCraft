defmodule VibeCraft.Map.Loader do
  @moduledoc """
  Loads a VibeCraft map from a plain-text `.map` file.

  ## File format

  Each non-comment, non-blank line is a row of tiles.  Each character encodes
  one tile:

  | Character | Tile type    |
  |-----------|--------------|
  | `G`       | `:grass`     |
  | `W`       | `:water`     |
  | `T`       | `:trees`     |
  | `R`       | `:rock`      |
  | `M`       | `:gold_mine` |

  Lines whose first non-whitespace character is `#` are treated as comments
  and are ignored.  All tile rows must have the same width.
  """

  alias VibeCraft.Map.{Map, Tile}

  @doc """
  Load a map from the file at `path`.

  Returns `{:ok, map}` on success or `{:error, reason}` on failure.
  """
  @spec load(Path.t()) :: {:ok, Map.t()} | {:error, term()}
  def load(path) do
    with {:ok, data} <- File.read(path) do
      parse(data)
    end
  end

  @doc """
  Parse a map from a string.

  Returns `{:ok, map}` on success or `{:error, reason}` on failure.
  """
  @spec parse(String.t()) :: {:ok, Map.t()} | {:error, term()}
  def parse(data) do
    rows =
      data
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(String.starts_with?(&1, "#") or &1 == ""))

    case rows do
      [] ->
        {:error, :empty_map}

      _ ->
        validate_and_build_map(rows)
    end
  end

  @spec validate_and_build_map([String.t()]) :: {:ok, Map.t()} | {:error, term()}
  defp validate_and_build_map(rows) do
    row_width = rows |> List.first() |> String.length()

    if Enum.all?(rows, fn row -> String.length(row) == row_width end) do
      build_map(rows)
    else
      {:error, :inconsistent_row_widths}
    end
  end

  @spec build_map([String.t()]) :: {:ok, Map.t()} | {:error, term()}
  defp build_map(rows) do
    case rows |> Enum.map(&parse_row/1) |> collect_results() do
      {:ok, tile_rows} -> {:ok, Map.new(tile_rows)}
      error -> error
    end
  end

  @spec parse_row(String.t()) :: {:ok, [Tile.t()]} | {:error, term()}
  defp parse_row(row) do
    row
    |> String.graphemes()
    |> Enum.map(&char_to_tile/1)
    |> collect_results()
  end

  @spec char_to_tile(String.t()) :: {:ok, Tile.t()} | {:error, term()}
  defp char_to_tile("G"), do: {:ok, Tile.new(:grass)}
  defp char_to_tile("W"), do: {:ok, Tile.new(:water)}
  defp char_to_tile("T"), do: {:ok, Tile.new(:trees)}
  defp char_to_tile("R"), do: {:ok, Tile.new(:rock)}
  defp char_to_tile("M"), do: {:ok, Tile.new(:gold_mine)}
  defp char_to_tile(c), do: {:error, {:unknown_tile_char, c}}

  @spec collect_results(list()) :: {:ok, list()} | {:error, term()}
  defp collect_results(results) do
    Enum.reduce_while(results, {:ok, []}, fn
      {:ok, val}, {:ok, acc} -> {:cont, {:ok, acc ++ [val]}}
      error, _ -> {:halt, error}
    end)
  end
end
