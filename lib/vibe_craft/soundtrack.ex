defmodule VibeCraft.Soundtrack do
  @moduledoc """
  Original soundtrack and voice-over stubs for Phase 3.

  This module enumerates all music tracks and unit voice-over lines.  The
  actual audio data is loaded by the SDL2_mixer NIF at runtime; at compile
  time every playback function returns `:stub` so that the rest of the
  engine can wire up audio hooks without requiring the native layer.

  ## Tracks

  | Atom             | When played                              |
  |------------------|------------------------------------------|
  | `:main_theme`    | Title screen and main menu               |
  | `:battle`        | In-game during active combat             |
  | `:victory`       | End screen when the player wins          |
  | `:defeat`        | End screen when the player loses         |
  | `:ambient_day`   | In-game during daytime (Phase 3 cycle)   |
  | `:ambient_night` | In-game during nighttime                 |

  ## Voiceover lines

  | Atom                 | Unit response                          |
  |----------------------|----------------------------------------|
  | `:unit_selected`     | Acknowledgement when a unit is clicked |
  | `:unit_move`         | Acknowledgement of a move command      |
  | `:unit_attack`       | Acknowledgement of an attack order     |
  | `:building_complete` | Building construction finished         |
  | `:unit_trained`      | Unit training finished                 |
  | `:spell_cast`        | Hero spell activation                  |
  """

  @type track ::
          :main_theme
          | :battle
          | :victory
          | :defeat
          | :ambient_day
          | :ambient_night

  @type voiceover ::
          :unit_selected
          | :unit_move
          | :unit_attack
          | :building_complete
          | :unit_trained
          | :spell_cast

  @tracks [
    :main_theme,
    :battle,
    :victory,
    :defeat,
    :ambient_day,
    :ambient_night
  ]

  @voiceovers [
    :unit_selected,
    :unit_move,
    :unit_attack,
    :building_complete,
    :unit_trained,
    :spell_cast
  ]

  @dialyzer {:nowarn_function, list_tracks: 0, list_voiceovers: 0}

  @doc "Return the list of all available music tracks."
  @spec list_tracks() :: [track()]
  def list_tracks, do: @tracks

  @doc "Return the list of all available voiceover lines."
  @spec list_voiceovers() :: [voiceover()]
  def list_voiceovers, do: @voiceovers

  @doc """
  Play the music `track`.

  Returns `:stub` in the current implementation; the SDL2_mixer NIF layer
  will return `:ok` once audio is initialised.
  """
  @spec play_track(track()) :: :stub
  def play_track(track) when track in @tracks, do: :stub

  @doc """
  Stop playback of `track`.

  Returns `:stub` in the current implementation.
  """
  @spec stop_track(track()) :: :stub
  def stop_track(track) when track in @tracks, do: :stub

  @doc """
  Play a voiceover `line` for `unit_type`.

  `line` selects the interaction context (selection, move, attack, etc.).
  Returns `:stub` in the current implementation.
  """
  @spec play_voiceover(voiceover(), atom()) :: :stub
  def play_voiceover(line, _unit_type) when line in @voiceovers, do: :stub
end
