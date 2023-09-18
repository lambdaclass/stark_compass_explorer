defmodule StarknetExplorer.Blockchain.UpdaterSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.UpdaterWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      UpdaterWorker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
