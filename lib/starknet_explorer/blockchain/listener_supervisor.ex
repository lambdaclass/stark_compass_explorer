defmodule StarknetExplorer.Blockchain.ListenerSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.ListenerWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      if Application.get_env(:starknet_explorer, :env) == :prod do
        [
          Supervisor.child_spec({ListenerWorker, [network: :mainnet, name: :listener_mainnet]},
            id: "listener_mainnet"
          ),
          Supervisor.child_spec({ListenerWorker, [network: :testnet, name: :listener_testnet]},
            id: "listener_testnet"
          ),
          Supervisor.child_spec({ListenerWorker, [network: :testnet2, name: :listener_testnet2]},
            id: "listener_testnet2"
          )
        ]
      else
        [
          Supervisor.child_spec({ListenerWorker, [network: :mainnet, name: :listener_mainnet]},
            id: "listener_mainnet"
          )
        ]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
