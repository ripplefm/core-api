defmodule RippleWeb.StationHistoryView do
  use RippleWeb, :view
  alias RippleWeb.TrackView

  def render("show.json", %{history: history}) do
    render_many(history, TrackView, "track_history.json")
  end
end
