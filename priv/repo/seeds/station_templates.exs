# This file is used to define preset stations that
# are automatically started and have auto player servers
# started to play tracks from the sources.
# You should return an array of station templates, each must be a map
# with the following keys: name, tags, sources
# Below is an example configuration
station_templates = [
  %{
    name: "Popular Music",
    tags: ["pop", "music", "dance", "popular"],
    sources: %{
      playlist: [
        "https://www.youtube.com/playlist?list=PLDcnymzs18LU4Kexrs91TVdfnplU3I5zs"
      ]
    }
  }
]
