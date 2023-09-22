defmodule StarknetExplorer.Blockchain.ListenerWorker do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(arg) do
    {:ok, arg}
  end
end
