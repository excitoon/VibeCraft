defmodule VibeCraft.Assets.Model do
  @moduledoc """
  3-D mesh data: vertices, normals, texture coordinates, and faces.

  A model stores the geometry of a 3-D object in a format ready for
  rendering or further processing.

  ## Fields

  - `vertices`   — list of `{x, y, z}` positions (floats).
  - `normals`    — list of `{nx, ny, nz}` direction vectors (floats).
  - `tex_coords` — list of `{u, v}` texture coordinates (floats, 0..1).
  - `faces`      — list of faces; each face is a list of vertex indices
    (1-based, matching the Wavefront OBJ convention).  Each index is a
    tuple `{v, vt, vn}` where `v` is required and `vt`/`vn` are
    optional (nil when absent).
  """

  @enforce_keys [:vertices, :faces]
  defstruct vertices: [],
            normals: [],
            tex_coords: [],
            faces: []

  @type vertex :: {float(), float(), float()}
  @type normal :: {float(), float(), float()}
  @type tex_coord :: {float(), float()}

  @typedoc """
  A single vertex reference inside a face.

  `{vertex_index, tex_coord_index | nil, normal_index | nil}`.
  Indices are 1-based.
  """
  @type face_vertex :: {pos_integer(), non_neg_integer() | nil, non_neg_integer() | nil}

  @type face :: [face_vertex(), ...]

  @type t :: %__MODULE__{
          vertices: [vertex()],
          normals: [normal()],
          tex_coords: [tex_coord()],
          faces: [face()]
        }

  @doc """
  Create a new model from geometry data.

  Raises `ArgumentError` when `vertices` is empty or `faces` is empty.
  """
  @spec new([vertex()], [face()], [normal()], [tex_coord()]) :: t()
  def new(vertices, faces, normals \\ [], tex_coords \\ [])

  def new([], _faces, _normals, _tex_coords) do
    raise ArgumentError, "vertices must not be empty"
  end

  def new(_vertices, [], _normals, _tex_coords) do
    raise ArgumentError, "faces must not be empty"
  end

  def new(vertices, faces, normals, tex_coords)
      when is_list(vertices) and is_list(faces) and
             is_list(normals) and is_list(tex_coords) do
    %__MODULE__{
      vertices: vertices,
      normals: normals,
      tex_coords: tex_coords,
      faces: faces
    }
  end
end
