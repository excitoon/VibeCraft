defmodule VibeCraft.Assets.ModelTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.Model

  describe "new/4" do
    test "creates a model with vertices and faces" do
      vertices = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      faces = [[{1, nil, nil}, {2, nil, nil}, {3, nil, nil}]]
      model = Model.new(vertices, faces)

      assert model.vertices == vertices
      assert model.faces == faces
      assert model.normals == []
      assert model.tex_coords == []
    end

    test "creates a model with normals and texture coordinates" do
      vertices = [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      normals = [{0.0, 0.0, 1.0}]
      tex_coords = [{0.0, 0.0}, {1.0, 0.0}, {0.0, 1.0}]
      faces = [[{1, 1, 1}, {2, 2, 1}, {3, 3, 1}]]

      model = Model.new(vertices, faces, normals, tex_coords)

      assert model.vertices == vertices
      assert model.normals == normals
      assert model.tex_coords == tex_coords
      assert model.faces == faces
    end

    test "raises ArgumentError when vertices is empty" do
      assert_raise ArgumentError, ~r/vertices must not be empty/, fn ->
        Model.new([], [[{1, nil, nil}]])
      end
    end

    test "raises ArgumentError when faces is empty" do
      assert_raise ArgumentError, ~r/faces must not be empty/, fn ->
        Model.new([{0.0, 0.0, 0.0}], [])
      end
    end
  end
end
