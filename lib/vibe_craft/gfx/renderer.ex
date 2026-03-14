defmodule VibeCraft.GFX.Renderer do
  @moduledoc """
  High-level 2-D sprite renderer backed by OpenGL 3.3 Core.

  All coordinates are in screen pixels with the origin at the top-left
  corner of the window; Y increases downward.

  ## Typical per-frame usage

      Renderer.clear(window)
      Renderer.draw_sprite(window, tex_id, x, y, sprite)
      Window.swap_buffers(window)
  """

  alias VibeCraft.Assets.Sprite
  alias VibeCraft.GFX.{NIF, Window}

  @dialyzer {:nowarn_function, [clear: 1, load_sprite: 2, draw_sprite: 5, unload_sprite: 2]}

  @doc """
  Clear the screen to black.  Call at the start of each frame.
  """
  @spec clear(Window.t()) :: :ok
  def clear(window), do: NIF.clear_screen(window)

  @doc """
  Upload a sprite to the GPU and return a texture ID.

  The texture ID is an opaque integer that identifies the GPU texture.
  Pass it to `draw_sprite/5` and, when done, to `unload_sprite/2`.
  """
  @spec load_sprite(Window.t(), Sprite.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def load_sprite(window, %Sprite{width: w, height: h, pixels: pixels}) do
    NIF.upload_texture(window, pixels, w, h)
  end

  @doc """
  Draw a previously uploaded sprite at screen position `{x, y}`.

  The sprite is rendered at its natural pixel dimensions.
  """
  @spec draw_sprite(Window.t(), non_neg_integer(), integer(), integer(), Sprite.t()) :: :ok
  def draw_sprite(window, texture_id, x, y, %Sprite{width: w, height: h}) do
    NIF.draw_sprite(window, texture_id, x, y, w, h)
  end

  @doc """
  Delete a GPU texture, freeing VRAM.
  """
  @spec unload_sprite(Window.t(), non_neg_integer()) :: :ok
  def unload_sprite(window, texture_id), do: NIF.delete_texture(window, texture_id)
end
