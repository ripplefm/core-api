defmodule Ripple.Tracks.Providers.SoundCloud do
  def api_key do
    System.get_env("SOUNDCLOUD_API_KEY")
  end

  def get_track(url) do
    url
    |> make_request
    |> process_body
    |> parse_track(url)
  end

  def make_request(url) do
    {:ok, res} =
      HTTPoison.get(
        "https://api.soundcloud.com/resolve?url=#{url}&client_id=#{api_key()}&limit=100",
        [],
        follow_redirect: true
      )

    res
  end

  def get_related_tracks(url) do
    track_uri = url |> make_request |> process_body |> Map.get("uri")

    {:ok, res} =
      HTTPoison.get(
        "#{track_uri}/related?client_id=#{api_key()}&limit=100",
        [],
        follow_redirect: true
      )

    res.body |> Poison.decode!()
  end

  def get_user_tracks(url) do
    make_request("#{url}/tracks") |> process_body
  end

  def get_playlist_tracks(url) do
    url |> make_request |> process_body |> Map.get("tracks")
  end

  def get_chart_tracks(url) do
    {:ok, res} = HTTPoison.get(url <> "&client_id=#{api_key()}")
    process_body(res) |> Map.get("collection") |> Enum.map(&Map.get(&1, "track"))
  end

  defp process_body(res) do
    res.body
    |> Poison.decode!()
  end

  defp parse_track(track, url) do
    %{
      name: track["title"],
      artwork_url: track["artwork_url"],
      poster: track["user"]["username"],
      duration: track["duration"],
      provider: "SoundCloud",
      url: url
    }
  end
end
