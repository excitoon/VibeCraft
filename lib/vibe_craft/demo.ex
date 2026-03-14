defmodule VibeCraft.Demo do
  @moduledoc """
  Phase-0 prototype: opens a window and renders the built-in cursor sprite.

  Run with:

      mix run -e "VibeCraft.Demo.run()"

  Press **Escape** or close the window to exit.
  """

  alias VibeCraft.Assets.Sprites
  alias VibeCraft.GFX.{Renderer, Window}

  @window_title "VibeCraft"
  @window_width 800
  @window_height 600
  @sprite_x 100
  @sprite_y 100

  @doc """
  Open a window, upload the cursor sprite, and enter the render loop.
  """
  @spec run() :: :ok
  def run do
    {:ok, window} = Window.open(@window_title, @window_width, @window_height)
    sprite = Sprites.cursor()
    {:ok, tex} = Renderer.load_sprite(window, sprite)
    loop(window, tex, sprite)
    Renderer.unload_sprite(window, tex)
    Window.close(window)
  end

  @spec loop(Window.t(), non_neg_integer(), VibeCraft.Assets.Sprite.t()) :: :ok
  defp loop(window, tex, sprite) do
    events = Window.poll_events(window)

    quit =
      Enum.any?(events, fn
        :quit -> true
        {:keydown, 27} -> true
        _ -> false
      end)

    unless quit do
      Renderer.clear(window)
      Renderer.draw_sprite(window, tex, @sprite_x, @sprite_y, sprite)
      Window.swap_buffers(window)
      loop(window, tex, sprite)
    end
  end
end
