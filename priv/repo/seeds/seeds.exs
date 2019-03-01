# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds/seeds.exs

# Load templates
{station_templates, _} =
  Code.eval_file("#{:code.priv_dir(:ripple)}/repo/seeds/station_templates.exs")

# Get or create user
{:ok, user} =
  case Ripple.Users.get_user("autoplayer") do
    {:error, :not_found} -> Ripple.Users.create_user(%{username: "autoplayer"})
    u -> {:ok, u}
  end

# Ensure all stations defined in templates exist
station_templates
|> Enum.filter(&(Ripple.Stations.get_station(&1.name |> Slug.slugify()) == {:error, :not_found}))
|> Enum.each(fn template ->
  Ripple.Stations.create_station(%{
    creator_id: user.id,
    name: template.name,
    tags: template.tags,
    visibility: "public"
  })
end)

# Create or update autoplayer configs for all stations defined in templates
station_templates
|> Enum.each(fn template ->
  {:ok, station} = template.name |> Slug.slugify() |> Ripple.Stations.get_station()
  Ripple.AutoPlayers.upsert_config(station, template.sources)
end)
