defmodule VibeCraft.GFX.Window do
  @moduledoc """
  Manages an SDL2 application window and its OpenGL 3.3 Core context.

  Obtain a window with `open/3`, hand it to `VibeCraft.GFX.Renderer` for
  drawing, and call `close/1` when done.  Call `poll_events/1` once per
  game-loop tick to drain the SDL2 event queue.
  """

  alias VibeCraft.GFX.NIF

  @dialyzer {:nowarn_function, [open: 3, poll_events: 1, swap_buffers: 1, close: 1]}

  @opaque t :: reference()

  @doc """
  Open a new window with the given title, width, and height in pixels.

  Returns `{:ok, window}` on success or `{:error, reason}` when SDL2 or
  OpenGL initialisation fails.
  """
  @spec open(String.t(), pos_integer(), pos_integer()) ::
          {:ok, t()} | {:error, String.t()}
  def open(title, width, height)
      when is_binary(title) and is_integer(width) and width > 0 and
             is_integer(height) and height > 0 do
    NIF.create_window(title, width, height)
  end

  @doc """
  Drain the SDL2 event queue and return a list of event terms.

  Each call collects all pending events; call once per game-loop tick.
  """
  @spec poll_events(t()) :: [atom() | tuple()]
  def poll_events(window), do: NIF.poll_events(window)

  @doc """
  Swap the front and back buffers, presenting the current frame.

  Call at the end of each game-loop tick after all drawing is complete.
  """
  @spec swap_buffers(t()) :: :ok
  def swap_buffers(window), do: NIF.swap_buffers(window)

  @doc """
  Close the window and release all associated GPU resources.
  """
  @spec close(t()) :: :ok
  def close(window), do: NIF.destroy_window(window)
end
