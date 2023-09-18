defmodule StarknetExplorer.Blockchain.ListenerWorker do
  @moduledoc """
  Periodically fetches the latests block from the Starknet Blockchain and inserts it into the database.
  """
  alias StarknetExplorer.{BlockUtils, Rpc, Blockchain.ListenerWorker}
  defstruct [:latest_block_number, :network]
  use GenServer
  require Logger
  @fetch_timer :timer.seconds(5)
  # TODO: parametrize this.
  @network :mainnet

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(_arg) do
    {:ok, block_height} = Rpc.get_block_height_no_cache(@network)

    state = %ListenerWorker{
      latest_block_number: block_height,
      # Use this parametrized.
      network: @network
    }

    Process.send_after(self(), :fetch_latest, @fetch_timer)
    Logger.info("Listener enabled")
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_latest, state = %ListenerWorker{network: network}) do
    {:ok, new_block_height} = Rpc.get_block_height_no_cache(network)
    new_blocks? = new_block_height > state.latest_block_number

    state =
      try_fetch(new_blocks?, state)

    Process.send_after(self(), :fetch_latest, @fetch_timer)
    {:noreply, state}
  end

  defp try_fetch(true, state = %ListenerWorker{network: network}) do
    next_to_fetch = state.latest_block_number + 1

    case BlockUtils.fetch_and_store(next_to_fetch, network) do
      {:ok, _} ->
        Logger.info("New block stored: #{next_to_fetch}")
        %{state | latest_block_number: next_to_fetch}

      {:error, err} ->
        Logger.error("[Block Listener] Error fetching latest block: #{inspect(err)}, retrying...")

        state
    end
  end

  defp try_fetch(_new_blocks?, state), do: state
end
