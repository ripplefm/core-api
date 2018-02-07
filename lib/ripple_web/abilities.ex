# For current user %{ scopes, username, id }
defimpl Canada.Can, for: Map do
  alias Ripple.Stations.Station

  def can?(%{scopes: scopes}, :create, Station) do
    "stations:write" in scopes
  end

  def can?(_, _, _), do: false
end

# No access token provided, user is anonymous
defimpl Canada.Can, for: Atom do
  def can?(_, _, _), do: false
end
