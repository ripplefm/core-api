defmodule Ripple.AutoPlayers.PlaySourceResolver do
  alias Ripple.Tracks.Providers.{YouTube, SoundCloud}

  def get_next_url(sources) when is_map(sources), do: get_next_url(Enum.random(sources))

  def get_next_url({"track", urls}) when is_list(urls), do: Enum.random(urls)

  def get_next_url({type, urls}) when is_list(urls), do: get_next_url({type, Enum.random(urls)})

  def get_next_url({type, url}), do: get_next_url({type, url}, get_provider(url))

  def get_next_url(_, :error), do: nil

  def get_next_url({"related", url}, :youtube) do
    url
    |> YouTube.get_related_videos()
    |> Enum.random()
    |> Map.get("id")
    |> Map.get("videoId")
    |> (&"https://www.youtube.com/watch?v=#{&1}").()
  end

  def get_next_url({"user", url}, :youtube) do
    url
    |> YouTube.get_channel_videos()
    |> Enum.random()
    |> Map.get("contentDetails")
    |> Map.get("videoId")
    |> (&"https://www.youtube.com/watch?v=#{&1}").()
  end

  def get_next_url({"playlist", url}, :youtube) do
    url
    |> YouTube.get_playlist_videos()
    |> Enum.random()
    |> Map.get("contentDetails")
    |> Map.get("videoId")
    |> (&"https://www.youtube.com/watch?v=#{&1}").()
  end

  def get_next_url({"chart", url}, :soundcloud) do
    SoundCloud.get_chart_tracks(url) |> Enum.random() |> Map.get("permalink_url")
  end

  def get_next_url({"related", url}, :soundcloud) do
    SoundCloud.get_related_tracks(url) |> Enum.random() |> Map.get("permalink_url")
  end

  def get_next_url({"user", url}, :soundcloud) do
    SoundCloud.get_user_tracks(url) |> Enum.random() |> Map.get("permalink_url")
  end

  def get_next_url({"playlist", url}, :soundcloud) do
    SoundCloud.get_playlist_tracks(url) |> Enum.random() |> Map.get("permalink_url")
  end

  defp get_provider(url) do
    host = URI.parse(url).host

    cond do
      String.contains?(host, "youtube") -> :youtube
      String.contains?(host, "soundcloud") -> :soundcloud
      true -> :error
    end
  end
end
