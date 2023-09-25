defmodule StarknetExplorer.Blockchain.FetcherSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.FetcherWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def stop_child(pid) do
    Supervisor.terminate_child(__MODULE__, pid)
  end

  @impl true
  def init(_init_arg) do
    finish = 0
    {:ok, start} = StarknetExplorer.Rpc.get_block_height_no_cache(:mainnet)

    children =
      if Application.get_env(:starknet_explorer, :env) == :prod do
        [
          Supervisor.child_spec({FetcherWorker, [start: start, finish: finish, network: :mainnet, name: :fetcher_mainnet]},
            id: "fetcher_mainnet"
          ),
          Supervisor.child_spec({FetcherWorker, [start: start, finish: finish, network: :testnet, name: :fetcher_testnet]},
            id: "fetcher_testnet"
          ),
          Supervisor.child_spec({FetcherWorker, [start: start, finish: finish, network: :testnet2, name: :fetcher_testnet2]},
            id: "fetcher_testnet2"
          )
        ]
      else
        [
          Supervisor.child_spec({FetcherWorker, [start: start, finish: finish, network: :mainnet, name: :fetcher_mainnet]},
            id: "fetcher_mainnet"
          )
        ]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
