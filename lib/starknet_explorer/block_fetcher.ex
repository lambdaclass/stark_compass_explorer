defmodule StarknetExplorer.BlockFetcher do
  use GenServer
  alias StarknetExplorer.Rpc
  # 1 minute
  @poll_interval 1000 * 60
  def start_links(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %{
      block_height: 0,
      new_blocks: []
    }

    Process.send_after(self(), :poll, @poll_interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch, state = %{}) do
    {:noreply, state}
  end
end
