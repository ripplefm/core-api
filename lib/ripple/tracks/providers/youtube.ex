defmodule Ripple.Tracks.Providers.YouTube do
  def api_key do
    System.get_env("YOUTUBE_API_KEY")
  end

  def base_url(resource, query) do
    "https://www.googleapis.com/youtube/v3/#{resource}?#{query}&maxResults=50&key=#{api_key()}"
  end

  def make_request(resource \\ "search", query \\ "") do
    {:ok, res} = HTTPoison.get(base_url(resource, query))
    res
  end

  def get_track(url) do
    url
    |> parse_id
    |> (&make_request("videos", "id=#{&1}&part=snippet,contentDetails")).()
    |> process_body
    |> List.first()
    |> parse_track(url)
  end

  def get_playlist_videos(url, full_playlist \\ true) do
    playlist = URI.parse(url).query |> URI.decode_query() |> Map.get("list")

    response =
      make_request("playlistItems", "part=snippet,contentDetails,status&playlistId=#{playlist}").body
      |> Poison.decode!()

    results_per_page = Map.get(response, "pageInfo") |> Map.get("resultsPerPage")
    total_results = Map.get(response, "pageInfo") |> Map.get("totalResults")

    pages = (total_results / results_per_page) |> Float.ceil() |> round

    {items, _} =
      Enum.reduce(
        1..pages,
        {Map.get(response, "items"), Map.get(response, "nextPageToken")},
        fn _, {items, next_page_token} ->
          res =
            make_request(
              "playlistItems",
              "part=snippet,contentDetails,status&playlistId=#{playlist}&pageToken=#{
                next_page_token
              }"
            ).body
            |> Poison.decode!()

          {items ++ Map.get(res, "items"), Map.get(res, "nextPageToken")}
        end
      )

    Enum.uniq(items)
  end

  def get_playlist_videos(url, false) do
    playlist = URI.parse(url).query |> URI.decode_query() |> Map.get("list")

    make_request("playlistItems", "part=snippet,contentDetails,status&playlistId=#{playlist}")
    |> process_body
  end

  def get_related_videos(url) do
    url
    |> parse_id
    |> (&make_request("search", "relatedToVideoId=#{&1}&part=snippet&type=video")).()
    |> process_body
  end

  def get_channel_videos(url) do
    channel_id = url |> String.split("/") |> List.last()

    type =
      case String.contains?(url, "/channel/") do
        true -> "id"
        false -> "forUsername"
      end

    playlist =
      make_request("channels", "part=contentDetails&#{type}=#{channel_id}")
      |> process_body
      |> List.first()
      |> Map.get("contentDetails")
      |> Map.get("relatedPlaylists")
      |> Map.get("uploads")

    get_playlist_videos("https://youtube.com/playlist?list=#{playlist}")
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

  defp process_body(res) do
    res.body
    |> Poison.decode!()
    |> Map.get("items")
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
