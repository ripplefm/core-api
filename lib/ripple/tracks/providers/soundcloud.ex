defmodule Ripple.Tracks.Providers.SoundCloud do
  @key System.get_env("SOUNDCLOUD_API_KEY")

  def get_track(url) do
    url
    |> make_request
    |> process_body
    |> parse_track(url)
  end

  defp make_request(url) do
    {:ok, res} =
      HTTPoison.get(
        "https://api.soundcloud.com/resolve?url=#{url}&client_id=#{@key}",
        [],
        follow_redirect: true
      )

    res
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
