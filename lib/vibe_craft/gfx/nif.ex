defmodule VibeCraft.GFX.NIF do
  @moduledoc """
  Thin Elixir wrappers around the SDL2/OpenGL native implementation.

  The NIF is compiled from `c_src/vibe_craft_nif.c` via `elixir_make` and
  loaded automatically when the module is first used.  All higher-level
  rendering logic lives in pure Elixir modules; only the render hot-path
  touches native code.
  """

  @on_load :load_nif

  @dialyzer {:nowarn_function,
             [
               load_nif: 0,
               create_window: 3,
               destroy_window: 1,
               poll_events: 1,
               swap_buffers: 1,
               clear_screen: 1,
               upload_texture: 4,
               draw_sprite: 6,
               delete_texture: 2
             ]}

  @doc false
  def load_nif do
    nif_path = Application.app_dir(:vibe_craft, "priv/vibe_craft_nif")
    :erlang.load_nif(nif_path, 0)
  end

  @doc """
  Open an SDL2 window with an OpenGL 3.3 Core context.

  Returns `{:ok, window_ref}` or `{:error, reason}`.
  """
  @spec create_window(String.t(), pos_integer(), pos_integer()) ::
          {:ok, reference()} | {:error, String.t()}
  def create_window(_title, _width, _height), do: err()

  @doc """
  Close an SDL2 window and free its OpenGL context.
  """
  @spec destroy_window(reference()) :: :ok
  def destroy_window(_window_ref), do: err()

  @doc """
  Drain the SDL2 event queue.

  Returns a list of event terms: `:quit`, `{:keydown, keycode}`,
  `{:keyup, keycode}`.
  """
  @spec poll_events(reference()) :: [atom() | tuple()]
  def poll_events(_window_ref), do: err()

  @doc """
  Swap the OpenGL front and back buffers.
  """
  @spec swap_buffers(reference()) :: :ok
  def swap_buffers(_window_ref), do: err()

  @doc """
  Clear the colour and depth buffers (black background).
  """
  @spec clear_screen(reference()) :: :ok
  def clear_screen(_window_ref), do: err()

  @doc """
  Upload RGBA pixel data to the GPU and return an integer texture ID.

  `pixels` must be a binary of exactly `width * height * 4` bytes in
  row-major RGBA order.
  """
  @spec upload_texture(reference(), binary(), pos_integer(), pos_integer()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def upload_texture(_window_ref, _rgba_pixels, _width, _height), do: err()

  @doc """
  Draw a textured quad at screen position `{x, y}` with size `{width, height}`.

  The coordinate origin is the top-left corner of the window, Y increases
  downward.
  """
  @spec draw_sprite(
          reference(),
          non_neg_integer(),
          integer(),
          integer(),
          pos_integer(),
          pos_integer()
        ) :: :ok
  def draw_sprite(_window_ref, _texture_id, _x, _y, _width, _height), do: err()

  @doc """
  Delete a GPU texture previously created with `upload_texture/4`.
  """
  @spec delete_texture(reference(), non_neg_integer()) :: :ok
  def delete_texture(_window_ref, _texture_id), do: err()

  defp err do
    :erlang.nif_error(:not_loaded)
  end
end
