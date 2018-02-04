defmodule Ripple.TracksTest do
  use Ripple.DataCase

  alias Ripple.Tracks

  describe "tracks" do
    alias Ripple.Tracks.Track

    @valid_attrs %{artwork_url: "some artwork_url", duration: 42, name: "some name", poster: "some poster", provider: "some provider", url: "some url"}
    @update_attrs %{artwork_url: "some updated artwork_url", duration: 43, name: "some updated name", poster: "some updated poster", provider: "some updated provider", url: "some updated url"}
    @invalid_attrs %{artwork_url: nil, duration: nil, name: nil, poster: nil, provider: nil, url: nil}

    def track_fixture(attrs \\ %{}) do
      {:ok, track} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tracks.create_track()

      track
    end

    test "list_tracks/0 returns all tracks" do
      track = track_fixture()
      assert Tracks.list_tracks() == [track]
    end

    test "get_track!/1 returns the track with given id" do
      track = track_fixture()
      assert Tracks.get_track!(track.id) == track
    end

    test "create_track/1 with valid data creates a track" do
      assert {:ok, %Track{} = track} = Tracks.create_track(@valid_attrs)
      assert track.artwork_url == "some artwork_url"
      assert track.duration == 42
      assert track.name == "some name"
      assert track.poster == "some poster"
      assert track.provider == "some provider"
      assert track.url == "some url"
    end

    test "create_track/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracks.create_track(@invalid_attrs)
    end

    test "update_track/2 with valid data updates the track" do
      track = track_fixture()
      assert {:ok, track} = Tracks.update_track(track, @update_attrs)
      assert %Track{} = track
      assert track.artwork_url == "some updated artwork_url"
      assert track.duration == 43
      assert track.name == "some updated name"
      assert track.poster == "some updated poster"
      assert track.provider == "some updated provider"
      assert track.url == "some updated url"
    end

    test "update_track/2 with invalid data returns error changeset" do
      track = track_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracks.update_track(track, @invalid_attrs)
      assert track == Tracks.get_track!(track.id)
    end

    test "delete_track/1 deletes the track" do
      track = track_fixture()
      assert {:ok, %Track{}} = Tracks.delete_track(track)
      assert_raise Ecto.NoResultsError, fn -> Tracks.get_track!(track.id) end
    end

    test "change_track/1 returns a track changeset" do
      track = track_fixture()
      assert %Ecto.Changeset{} = Tracks.change_track(track)
    end
  end
end
