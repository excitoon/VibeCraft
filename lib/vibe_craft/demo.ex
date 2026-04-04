defmodule VibeCraft.Demo do
  @moduledoc """
  Phase-0 prototype: opens a window and renders a tiled grass background with
  the built-in cursor sprite on top.

  Run with:

      mix run -e "VibeCraft.Demo.run()"

  Press **Escape** or close the window to exit.
  """

  alias VibeCraft.Assets.Sprites
  alias VibeCraft.GFX.{Renderer, Window}

  @dialyzer {:nowarn_function, run: 0, loop: 5, draw_background: 4}

  @window_title "VibeCraft"
  @window_width 800
  @window_height 600
  @tile_size 16
  @cursor_x 100
  @cursor_y 100

  @doc """
  Open a window, upload sprites, and enter the render loop.
  """
  @spec run() :: :ok
  def run do
    {:ok, window} = Window.open(@window_title, @window_width, @window_height)
    grass = Sprites.terrain_grass()
    cursor = Sprites.cursor()
    {:ok, grass_tex} = Renderer.load_sprite(window, grass)
    {:ok, cursor_tex} = Renderer.load_sprite(window, cursor)
    loop(window, grass_tex, grass, cursor_tex, cursor)
    Renderer.unload_sprite(window, cursor_tex)
    Renderer.unload_sprite(window, grass_tex)
    Window.close(window)
  end

  @spec loop(
          Window.t(),
          non_neg_integer(),
          VibeCraft.Assets.Sprite.t(),
          non_neg_integer(),
          VibeCraft.Assets.Sprite.t()
        ) :: :ok
  defp loop(window, grass_tex, grass, cursor_tex, cursor) do
    events = Window.poll_events(window)

    quit =
      Enum.any?(events, fn
        :quit -> true
        {:keydown, 27} -> true
        _ -> false
      end)

    unless quit do
      Renderer.clear(window)
      draw_background(window, grass_tex, grass, @tile_size)
      Renderer.draw_sprite(window, cursor_tex, @cursor_x, @cursor_y, cursor)
      Window.swap_buffers(window)
      loop(window, grass_tex, grass, cursor_tex, cursor)
    end
  end

  @spec draw_background(Window.t(), non_neg_integer(), VibeCraft.Assets.Sprite.t(), pos_integer()) ::
          :ok
  defp draw_background(window, tex, sprite, tile_size) do
    cols = div(@window_width + tile_size - 1, tile_size)
    rows = div(@window_height + tile_size - 1, tile_size)

    for row <- 0..(rows - 1), col <- 0..(cols - 1) do
      Renderer.draw_sprite(window, tex, col * tile_size, row * tile_size, sprite)
    end

    :ok
  end
end
