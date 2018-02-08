defmodule Ripple.TracksTest do
  use Ripple.DataCase

  alias Ripple.Tracks

  describe "tracks" do
    alias Ripple.Tracks.Track

    @valid_youtube_url "https://www.youtube.com/watch?v=4Rc-NGWEHdU"
    @valid_soundcloud_url "https://soundcloud.com/sva-jus/akrosonix-mystery-kate-wild-vocal"
    @invalid_provider_url "https://youtube.com"
    @malformed_url ""

    def track_fixture() do
      Tracks.create_track(@valid_youtube_url)
    end

    test "get_or_create_track/1 returns the track with given url" do
      track = track_fixture()
      assert Tracks.get_or_create_track(track.url) == track
    end

    test "get_or_create_track/1 creates the track if it doesn't exist" do
      assert %Track{} = track = Tracks.get_or_create_track(@valid_soundcloud_url)
      assert track.duration == 303_989
      assert track.name == "Akrosonix - Mystery (Kate Wild Vocal)"
      assert track.provider == "SoundCloud"
      assert track.url == @valid_soundcloud_url
    end

    test "create_track/1 with valid url creates a track" do
      assert %Track{} = track = Tracks.create_track(@valid_soundcloud_url)
      assert track.duration == 303_989
      assert track.name == "Akrosonix - Mystery (Kate Wild Vocal)"
      assert track.provider == "SoundCloud"
      assert track.url == @valid_soundcloud_url
    end

    test "create_track/1 with invalid provider url raises exception" do
      assert_raise ArgumentError, "Invalid track provider url", fn ->
        Tracks.create_track(@invalid_provider_url)
      end
    end

    test "create_track/1 with malformed url raises exception" do
      assert_raise ArgumentError, "Invalid track provider url", fn ->
        Tracks.create_track(@malformed_url)
      end
    end

    test "change_track/1 returns a track changeset" do
      track = track_fixture()
      assert %Ecto.Changeset{} = Tracks.change_track(track)
    end
  end
end
