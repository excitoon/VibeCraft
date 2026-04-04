defmodule VibeCraft.Assets.ModelLoader do
  @moduledoc """
  Wavefront OBJ loader for VibeCraft 3-D models.

  The [Wavefront OBJ](https://en.wikipedia.org/wiki/Wavefront_.obj_file)
  format was chosen because it is **plain text**, making it readable,
  diffable, and Git-friendly.  Every vertex, normal, and face is a
  human-readable line — changes show up clearly in pull-request diffs.

  ## Supported directives

  | Prefix | Meaning                     |
  |--------|-----------------------------|
  | `v`    | Vertex position  (x y z)    |
  | `vn`   | Vertex normal    (x y z)    |
  | `vt`   | Texture coord    (u v)      |
  | `f`    | Face (triangle / polygon)   |
  | `#`    | Comment (ignored)           |

  Lines beginning with any other prefix are silently skipped, which
  keeps the loader tolerant of material-library (`mtllib`, `usemtl`)
  and group (`g`, `o`, `s`) directives exported by most 3-D tools.

  Returns `{:ok, %VibeCraft.Assets.Model{}}` or `{:error, reason}`.
  """

  alias VibeCraft.Assets.Model

  @doc """
  Load a 3-D model from a Wavefront OBJ file at `path`.
  """
  @spec load(Path.t()) :: {:ok, Model.t()} | {:error, term()}
  def load(path) do
    with {:ok, data} <- File.read(path) do
      parse(data)
    end
  end

  @doc """
  Parse a Wavefront OBJ string into a `Model` struct.
  """
  @spec parse(String.t()) :: {:ok, Model.t()} | {:error, term()}
  def parse(data) when is_binary(data) do
    lines = String.split(data, ~r/\r?\n/)

    {vertices, normals, tex_coords, faces} =
      Enum.reduce(lines, {[], [], [], []}, fn line, acc ->
        line
        |> String.trim()
        |> parse_line(acc)
      end)

    vertices = Enum.reverse(vertices)
    normals = Enum.reverse(normals)
    tex_coords = Enum.reverse(tex_coords)
    faces = Enum.reverse(faces)

    if vertices == [] or faces == [] do
      {:error, :empty_model}
    else
      {:ok, Model.new(vertices, faces, normals, tex_coords)}
    end
  end

  # ── line parsers ──────────────────────────────────────────────────────────

  defp parse_line("v " <> rest, {vs, ns, ts, fs}) do
    {x, y, z} = parse_vec3(rest)
    {[{x, y, z} | vs], ns, ts, fs}
  end

  defp parse_line("vn " <> rest, {vs, ns, ts, fs}) do
    {x, y, z} = parse_vec3(rest)
    {vs, [{x, y, z} | ns], ts, fs}
  end

  defp parse_line("vt " <> rest, {vs, ns, ts, fs}) do
    {u, v} = parse_vec2(rest)
    {vs, ns, [{u, v} | ts], fs}
  end

  defp parse_line("f " <> rest, {vs, ns, ts, fs}) do
    face =
      rest
      |> String.split()
      |> Enum.map(&parse_face_vertex/1)

    {vs, ns, ts, [face | fs]}
  end

  # Ignore comments and unrecognised lines.
  defp parse_line(_line, acc), do: acc

  # ── value parsers ─────────────────────────────────────────────────────────

  defp parse_vec3(text) do
    [x, y, z] =
      text
      |> String.split()
      |> Enum.take(3)
      |> Enum.map(&parse_float/1)

    {x, y, z}
  end

  defp parse_vec2(text) do
    [u, v] =
      text
      |> String.split()
      |> Enum.take(2)
      |> Enum.map(&parse_float/1)

    {u, v}
  end

  # Face vertex formats: "v", "v/vt", "v/vt/vn", "v//vn"
  defp parse_face_vertex(token) do
    case String.split(token, "/") do
      [v] ->
        {parse_int(v), nil, nil}

      [v, ""] ->
        {parse_int(v), nil, nil}

      [v, vt] ->
        {parse_int(v), parse_int(vt), nil}

      [v, "", vn] ->
        {parse_int(v), nil, parse_int(vn)}

      [v, vt, vn] ->
        {parse_int(v), parse_int(vt), parse_int(vn)}
    end
  end

  defp parse_float(s), do: s |> String.trim() |> String.to_float()

  defp parse_int(s), do: s |> String.trim() |> String.to_integer()
end
