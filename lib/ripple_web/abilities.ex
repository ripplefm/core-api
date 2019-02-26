# For current user %{ scopes, username, id }
defimpl Canada.Can, for: Ripple.Users.User do
  alias Ripple.Stations.{Station, StationFollower}
  alias Ripple.Playlists.{Playlist, PlaylistFollower}

  def can?(%{scopes: scopes}, :create, Station) do
    "stations:write" in scopes
  end

  def can?(%{scopes: scopes}, action, StationFollower) when action in [:create, :delete] do
    "stations:write" in scopes
  end

  def can?(%{scopes: scopes}, action, %Playlist{}) when action in [:add, :remove] do
    "playlists:write" in scopes
  end

  def can?(%{scopes: scopes}, :show, %Playlist{} = playlist) do
    playlist.visibility === "public" or
      ("playlists:read" in scopes or "playlists:write" in scopes)
  end

  def can?(%{scopes: scopes}, :create, Playlist) do
    "playlists:write" in scopes
  end

  def can?(%{scopes: scopes}, action, PlaylistFollower) when action in [:create, :delete] do
    "playlists:write" in scopes
  end

  # plug will move on to the "not_found" handler
  def can?(_, _, nil), do: true

  def can?(_, _, _), do: false
end

# No access token provided, user is anonymous
defimpl Canada.Can, for: Atom do
  alias Ripple.Playlists.Playlist

  def can?(_, :show, %Playlist{}), do: true

  # plug will move on to the "not_found" handler
  def can?(_, _, nil), do: true

  def can?(_, _, _), do: false
end
