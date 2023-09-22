defmodule StarknetExplorer.Blockchain.BlockchainSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.{ListenerSupervisor, UpdaterSupervisor}

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      ListenerSupervisor,
      UpdaterSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
