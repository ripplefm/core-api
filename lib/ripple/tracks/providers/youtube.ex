defmodule Ripple.Tracks.Providers.YouTube do
  @key System.get_env("YOUTUBE_API_KEY")

  def get_track(url) do
    url
    |> parse_id
    |> make_request
    |> process_body
    |> parse_track(url)
  end

  defp parse_id(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
    |> URI.query_decoder()
    |> Enum.to_list()
    |> Enum.at(0)
    |> elem(1)
  end

  defp make_request(id) do
    {:ok, res} =
      HTTPoison.get(
        "https://content.googleapis.com/youtube/v3/videos?id=#{id}&part=snippet,contentDetails&key=#{
          @key
        }"
      )

    res
  end

  defp process_body(res) do
    res.body
    |> Poison.decode!()
    |> Map.get("items")
    |> Enum.at(0)
  end

  defp parse_track(track, url) do
    %{
      name: track["snippet"]["title"],
      artwork_url: track["snippet"]["thumbnails"]["high"]["url"],
      poster: track["snippet"]["channelTitle"],
      duration: parse_duration(track["contentDetails"]["duration"]),
      provider: "YouTube",
      url: url
    }
  end

  defp parse_duration(duration) do
    duration
    |> String.slice(2, String.length(duration))
    |> String.replace("H", "* 60000 * 60 +")
    |> String.replace("M", "* 60000 +")
    |> String.replace("S", "* 1000")
    |> String.replace_suffix("+", "")
    |> Code.eval_string()
    |> elem(0)
  end
end
