defmodule Ripple.Stations.StationStore do
  alias :mnesia, as: Mnesia

  @table __MODULE__

  def init_store do
    # essentially a workaround to create same table as :lbm_kv but of type 'ordered_set',
    # based on: https://github.com/lindenbaum/lbm_kv/blob/e54c448207664bcfc0240f1177b905955cde6b5e/include/lbm_kv.hrl#L30-L44
    Mnesia.create_table(@table,
      record_name: :lbm_kv,
      ram_copies: [Node.self() | Node.list()],
      attributes: [:key, :val, :ver],
      cookie: {{0, 0, 0}, :lbm_kv},
      type: :ordered_set
    )

    :lbm_kv.create(@table)

    EventBus.subscribe({__MODULE__, ["station_*"]})
  end

  def read(slug) do
    case :lbm_kv.match(@table, {:_, slug}, :_) do
      {:ok, []} -> {:ok, nil}
      {:ok, [{_, station}]} -> {:ok, station}
      _ -> {:ok, nil}
    end
  end

  def save(station) do
    user_count = get_station_user_count(station)
    {:ok, saved} = read(station.slug)

    if saved != nil do
      saved_user_count = get_station_user_count(saved)

      if saved_user_count != user_count do
        # kind of a hack around the way lbm_kv stores records, we
        # do the replacement in a transaction to avoid race conditions
        tx = fn ->
          [tmp] = Mnesia.read(@table, {saved_user_count, station.slug})
          old_version = elem(tmp, 3)
          new_version = :lbm_kv_vclock.increment(Node.self(), old_version)
          new = {elem(tmp, 0), {user_count, station.slug}, station, new_version}

          Mnesia.delete({@table, {saved_user_count, station.slug}})
          Mnesia.write(@table, new, :write)
        end

        {:atomic, :ok} = Mnesia.transaction(tx)
        :ok
      else
        {:ok, _} = :lbm_kv.put(@table, {user_count, station.slug}, station)
        :ok
      end
    else
      {:ok, _} = :lbm_kv.put(@table, {user_count, station.slug}, station)
      :ok
    end
  end

  def delete(slug) do
    {:ok, saved} = read(slug)

    if saved != nil do
      saved_user_count = get_station_user_count(saved)

      {:ok, _} = :lbm_kv.del(@table, {saved_user_count, slug})
      :ok
    else
      {:error, :no_exists}
    end
  end

  def list_stations(start \\ 0, e \\ 10) do
    {:ok, res} = :lbm_kv.match(@table, :_, %{play_type: "public"})

    stations = res |> Stream.map(&elem(&1, 1)) |> Enum.reverse() |> Enum.slice(start, e)

    {:ok, stations}
  end

  def num_stations do
    Mnesia.table_info(@table, :size)
  end

  def list_nodes do
    Mnesia.table_info(@table, :ram_copies)
  end

  def clear_and_save(stations) do
    tx = fn ->
      Mnesia.match_object(@table, Mnesia.table_info(@table, :wild_pattern), :read)
      |> Enum.map(&elem(&1, 1))
      |> Enum.each(&Mnesia.delete({@table, &1}))

      stations
      |> Enum.each(fn station ->
        version = :lbm_kv_vclock.increment(Node.self(), [])
        user_count = get_station_user_count(station)
        Mnesia.write(@table, {:lbm_kv, {user_count, station.slug}, station, version}, :write)
      end)
    end

    {:atomic, :ok} = Mnesia.transaction(tx)

    :ok
  end

  def process({:station_stopped, id} = e) do
    event = EventBus.fetch_event(e)
    delete(event.data.station.slug)
    EventBus.mark_as_completed({__MODULE__, :station_stopped, id})
  end

  def process({topic, id} = e) do
    event = EventBus.fetch_event(e)
    save(event.data.station)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  defp get_station_user_count(station) do
    Enum.count(Map.get(station, :users, [])) + Map.get(station, :guests, 0)
  end
end
