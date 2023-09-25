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
    {:ok, start_mainnet} = StarknetExplorer.Rpc.get_block_height_no_cache(:mainnet)
    {:ok, start_testnet} = StarknetExplorer.Rpc.get_block_height_no_cache(:testnet)
    {:ok, start_testnet2} = StarknetExplorer.Rpc.get_block_height_no_cache(:testnet2)

    children =
      if Application.get_env(:starknet_explorer, :env) == :prod do
        [
          Supervisor.child_spec(
            {FetcherWorker,
             [start: start_mainnet, finish: finish, network: :mainnet, name: :fetcher_mainnet]},
            id: "fetcher_mainnet"
          ),
          Supervisor.child_spec(
            {FetcherWorker,
             [start: start_testnet, finish: finish, network: :testnet, name: :fetcher_testnet]},
            id: "fetcher_testnet"
          ),
          Supervisor.child_spec(
            {FetcherWorker,
             [start: start_testnet2, finish: finish, network: :testnet2, name: :fetcher_testnet2]},
            id: "fetcher_testnet2"
          )
        ]
      else
        [
          Supervisor.child_spec(
            {FetcherWorker,
             [start: start_mainnet, finish: finish, network: :mainnet, name: :fetcher_mainnet]},
            id: "fetcher_mainnet"
          )
        ]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
