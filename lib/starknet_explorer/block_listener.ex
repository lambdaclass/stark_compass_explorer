defmodule StarknetExplorer.BlockListener do
  use GenServer, restart: :temporary
  require Logger
  alias StarknetExplorer.{Rpc, BlockListener, Block, BlockUtils}
  defstruct [:latest_block_number_fetched, :lowest_block_number_fetched]
  @fetch_latest_interval 100
  @fetch_backwards_interval 400

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    block_height = BlockUtils.block_height()

    state = %BlockListener{
      latest_block_number_fetched: block_height,
      lowest_block_number_fetched: Block.lowest_block_number() || block_height
    }

    Process.send_after(self(), :fetch_backwards, @fetch_backwards_interval)

    Logger.info("Listener enabled")
    {:ok, state}
  end

  def handle_info(:fetch_latest, state = %BlockListener{}) do
    new_height = BlockUtils.block_height()
    highest_fetched = state.latest_block_number_fetched

    state =
      if new_height > highest_fetched do
        case BlockUtils.fetch_and_store(highest_fetched + 1) do
          :ok ->
            1

          {:error, err} ->
            1
        end
      else
        state
      end

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    {:noreply, state}
  end

  def handle_info(:fetch_backwards, state = %BlockListener{}) do
    to_fetch = state.lowest_block_number_fetched - 1

    state =
      case Rpc.get_block_by_number(to_fetch, :gateway_mainnet) do
        {:ok, block} ->
          Logger.info("Block #{to_fetch} fetched succesfully!")
          %{state | lowest_block_number_fetched: to_fetch}

        {:error, err} ->
          Logger.error("Error fetching block number #{to_fetch}: #{inspect(err)}")
          state
      end

    Process.send_after(self(), :fetch_backwards, @fetch_backwards_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end
end
