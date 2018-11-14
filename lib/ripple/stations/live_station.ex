defmodule Ripple.Stations.LiveStation do
  alias Ripple.Tracks.Track

  defstruct id: "",
            name: "",
            play_type: "",
            slug: "",
            tags: [],
            creator_id: "",
            guests: 0,
            users: [],
            current_track: %Track{},
            queue: []
end