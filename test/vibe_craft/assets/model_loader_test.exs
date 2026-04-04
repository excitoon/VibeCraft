defmodule VibeCraft.Assets.ModelLoaderTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Assets.{Model, ModelLoader}

  # ── helpers ──────────────────────────────────────────────────────────────

  defp tmp(name), do: Path.join(System.tmp_dir!(), "vibe_craft_test_#{name}")

  defp write_tmp(name, data) do
    path = tmp(name)
    File.write!(path, data)
    on_exit(fn -> File.rm(path) end)
    path
  end

  # ── parse/1 ─────────────────────────────────────────────────────────────

  describe "parse/1" do
    test "parses a minimal triangle" do
      obj = """
      # A triangle
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      f 1 2 3
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      assert length(model.vertices) == 3
      assert length(model.faces) == 1
      assert model.normals == []
      assert model.tex_coords == []

      [face] = model.faces
      assert face == [{1, nil, nil}, {2, nil, nil}, {3, nil, nil}]
    end

    test "parses vertices with normals (v//vn format)" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      vn 0.0 0.0 1.0
      f 1//1 2//1 3//1
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      assert length(model.normals) == 1
      assert hd(model.normals) == {0.0, 0.0, 1.0}

      [face] = model.faces
      assert face == [{1, nil, 1}, {2, nil, 1}, {3, nil, 1}]
    end

    test "parses full v/vt/vn face format" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      vt 0.0 0.0
      vt 1.0 0.0
      vt 0.0 1.0
      vn 0.0 0.0 1.0
      f 1/1/1 2/2/1 3/3/1
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      assert length(model.tex_coords) == 3
      assert hd(model.tex_coords) == {0.0, 0.0}

      [face] = model.faces
      assert face == [{1, 1, 1}, {2, 2, 1}, {3, 3, 1}]
    end

    test "parses v/vt face format (no normals)" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      vt 0.0 0.0
      vt 1.0 0.0
      vt 0.0 1.0
      f 1/1 2/2 3/3
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)

      [face] = model.faces
      assert face == [{1, 1, nil}, {2, 2, nil}, {3, 3, nil}]
    end

    test "ignores comments and unknown directives" do
      obj = """
      # comment line
      mtllib material.mtl
      usemtl default
      o MyObject
      g group1
      s off
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      f 1 2 3
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      assert length(model.vertices) == 3
      assert length(model.faces) == 1
    end

    test "handles quad faces (4 vertices per face)" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 1.0 1.0 0.0
      v 0.0 1.0 0.0
      f 1 2 3 4
      """

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      [face] = model.faces
      assert length(face) == 4
    end

    test "returns error for empty content" do
      assert {:error, :empty_model} = ModelLoader.parse("")
    end

    test "returns error for content with no geometry" do
      obj = """
      # only comments
      # no vertices or faces
      """

      assert {:error, :empty_model} = ModelLoader.parse(obj)
    end

    test "returns error for vertices without faces" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      """

      assert {:error, :empty_model} = ModelLoader.parse(obj)
    end

    test "handles Windows-style line endings" do
      obj = "v 0.0 0.0 0.0\r\nv 1.0 0.0 0.0\r\nv 0.0 1.0 0.0\r\nf 1 2 3\r\n"

      assert {:ok, %Model{} = model} = ModelLoader.parse(obj)
      assert length(model.vertices) == 3
    end
  end

  # ── load/1 ──────────────────────────────────────────────────────────────

  describe "load/1" do
    test "loads a valid .obj file from disk" do
      obj = """
      v 0.0 0.0 0.0
      v 1.0 0.0 0.0
      v 0.0 1.0 0.0
      f 1 2 3
      """

      path = write_tmp("triangle.obj", obj)
      assert {:ok, %Model{}} = ModelLoader.load(path)
    end

    test "returns error when file does not exist" do
      assert {:error, :enoent} = ModelLoader.load("/nonexistent/path/model.obj")
    end

    test "loads the built-in fighter.obj model" do
      path = Application.app_dir(:vibe_craft, "priv/models/fighter.obj")
      assert {:ok, %Model{} = model} = ModelLoader.load(path)

      # Fighter should have meaningful geometry
      assert length(model.vertices) > 50
      assert length(model.faces) > 40
      assert length(model.normals) == 6
    end

    test "fighter model vertices are within expected bounds" do
      path = Application.app_dir(:vibe_craft, "priv/models/fighter.obj")
      {:ok, model} = ModelLoader.load(path)

      for {x, y, z} <- model.vertices do
        assert x >= -1.0 and x <= 1.0, "x=#{x} out of bounds"
        assert y >= -0.1 and y <= 2.5, "y=#{y} out of bounds"
        assert z >= -0.5 and z <= 0.5, "z=#{z} out of bounds"
      end
    end

    test "fighter model faces reference valid vertex indices" do
      path = Application.app_dir(:vibe_craft, "priv/models/fighter.obj")
      {:ok, model} = ModelLoader.load(path)

      vertex_count = length(model.vertices)
      normal_count = length(model.normals)

      for face <- model.faces, {v, _vt, vn} <- face do
        assert v >= 1 and v <= vertex_count,
               "vertex index #{v} out of range 1..#{vertex_count}"

        if vn do
          assert vn >= 1 and vn <= normal_count,
                 "normal index #{vn} out of range 1..#{normal_count}"
        end
      end
    end

    test "fighter model has all triangular faces" do
      path = Application.app_dir(:vibe_craft, "priv/models/fighter.obj")
      {:ok, model} = ModelLoader.load(path)

      for face <- model.faces do
        assert length(face) == 3, "expected triangle, got #{length(face)}-gon"
      end
    end
  end
end
