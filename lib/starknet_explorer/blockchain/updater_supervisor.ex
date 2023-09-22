defmodule StarknetExplorer.Blockchain.UpdaterSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.UpdaterWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      if Mix.env() == :prod do
        [
          Supervisor.child_spec({UpdaterWorker, [network: :mainnet, name: :updater_mainnet]},
            id: "updater_mainnet"
          ),
          Supervisor.child_spec({UpdaterWorker, [network: :testnet, name: :updater_testnet]},
            id: "updater_testnet"
          ),
          Supervisor.child_spec({UpdaterWorker, [network: :testnet2, name: :updater_testnet2]},
            id: "updater_testnet2"
          )
        ]
      else
        [
          Supervisor.child_spec({UpdaterWorker, [network: :mainnet, name: :updater_mainnet]},
            id: "updater_mainnet"
          )
        ]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
