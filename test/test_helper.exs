{_, 0} = System.cmd("epmd", ["-daemon"])

# reset mnesia since it initializes with :"nonode@nohost"
:mnesia.stop()
:mnesia.delete_schema([Node.self()])
Node.start(:"primary@127.0.0.1", :longnames)
:mnesia.start()
Ripple.Stations.StationStore.init_store()

Application.ensure_all_started(:ex_unit_clustered_case)

ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(Ripple.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Ripple.Repo, {:shared, self()})
