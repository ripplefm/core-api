defmodule Ripple.Stations.StationHandoffStore do
  alias :mnesia, as: Mnesia
  alias Ripple.Stations.LiveStation

  @table __MODULE__

  def init_store do
    :lbm_kv.create(@table)
  end

  def put(nil), do: :ok

  def put(%LiveStation{} = station) do
    :lbm_kv.put(@table, station.slug, station)
    :ok
  end

  def get_and_delete(slug) do
    tx = fn ->
      [{_, _, station, _}] = Mnesia.read(@table, slug)
      Mnesia.delete({@table, slug})
      station
    end

    case Mnesia.transaction(tx) do
      {:atomic, station} -> {:ok, station}
      _ -> {:error, :no_exists}
    end
  end
end
