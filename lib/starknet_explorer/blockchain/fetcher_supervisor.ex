defmodule StarknetExplorer.Blockchain.FetcherSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.FetcherWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      FetcherWorker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
