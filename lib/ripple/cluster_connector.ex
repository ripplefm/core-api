defmodule Ripple.ClusterConnector do
  require Logger

  def connect(node) do
    node_res = Node.connect(node)

    Horde.Cluster.join_hordes(
      Ripple.StationStoreSyncSupervisor,
      {Ripple.StationStoreSyncSupervisor, node}
    )

    Horde.Cluster.join_hordes(
      Ripple.StationAutoPlayerSupervisor,
      {Ripple.StationAutoPlayerSupervisor, node}
    )

    Horde.Cluster.join_hordes(Ripple.StationSupervisor, {Ripple.StationSupervisor, node})
    Horde.Cluster.join_hordes(Ripple.StationRegistry, {Ripple.StationRegistry, node})

    node_res
  end
end
