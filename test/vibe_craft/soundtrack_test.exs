defmodule VibeCraft.SoundtrackTest do
  use ExUnit.Case, async: true

  alias VibeCraft.Soundtrack

  describe "list_tracks/0" do
    test "returns a non-empty list" do
      tracks = Soundtrack.list_tracks()
      assert is_list(tracks)
      assert length(tracks) > 0
    end

    test "includes expected track atoms" do
      tracks = Soundtrack.list_tracks()
      assert :main_theme in tracks
      assert :battle in tracks
      assert :victory in tracks
      assert :defeat in tracks
      assert :ambient_day in tracks
      assert :ambient_night in tracks
    end
  end

  describe "list_voiceovers/0" do
    test "returns a non-empty list" do
      voiceovers = Soundtrack.list_voiceovers()
      assert is_list(voiceovers)
      assert length(voiceovers) > 0
    end

    test "includes expected voiceover atoms" do
      voiceovers = Soundtrack.list_voiceovers()
      assert :unit_selected in voiceovers
      assert :unit_move in voiceovers
      assert :unit_attack in voiceovers
      assert :building_complete in voiceovers
      assert :unit_trained in voiceovers
      assert :spell_cast in voiceovers
    end
  end

  describe "play_track/1" do
    test "returns :stub for each defined track" do
      Enum.each(Soundtrack.list_tracks(), fn track ->
        assert Soundtrack.play_track(track) == :stub
      end)
    end
  end

  describe "stop_track/1" do
    test "returns :stub for each defined track" do
      Enum.each(Soundtrack.list_tracks(), fn track ->
        assert Soundtrack.stop_track(track) == :stub
      end)
    end
  end

  describe "play_voiceover/2" do
    test "returns :stub for each defined voiceover" do
      Enum.each(Soundtrack.list_voiceovers(), fn line ->
        assert Soundtrack.play_voiceover(line, :footman) == :stub
      end)
    end
  end
end
