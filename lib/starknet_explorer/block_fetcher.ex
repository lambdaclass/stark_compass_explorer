defmodule StarknetExplorer.BlockFetcher do
  use GenServer, restart: :temporary
  require Logger
  alias StarknetExplorer.{Rpc, BlockFetcher, Block}
  defstruct [:latest_block_number_fetched]
  @fetch_latest_interval 100
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %BlockFetcher{
      latest_block_number_fetched: block_height()
    }

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    Logger.info("Starting explorer with fetcher enabled!")
    {:ok, state}
  end

  def handle_info(:fetch_latest, state = %BlockFetcher{}) do
    new_height = block_height()
    highest_fetched = state.latest_block_number_fetched

    state =
      if new_height > highest_fetched do
        fetch_and_store(highest_fetched + 1, state)
      else
        state
      end

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end

  defp fetch_and_store(block_height, state = %BlockFetcher{}) do
    with {:ok, block} <- fetch_block(block_height),
         :ok <- store_block(block) do
      Logger.info("Inserted new block: #{block_height}")
      %{state | latest_block_number_fetched: block_height}
    else
      err ->
        Logger.error("Fetcher failed with: #{inspect(err)}")
        state
    end
  end

  defp store_block(block = %{"transactions" => transactions}) do
    receipts =
      transactions
      |> Map.new(fn %{"transaction_hash" => tx_hash} ->
        {:ok, receipt} = Rpc.get_transaction_receipt(tx_hash, :mainnet)
        {tx_hash, receipt}
      end)

    Block.insert_from_rpc_response(block, receipts)
  end

  defp block_height() do
    case Rpc.get_block_height_no_cache(:mainnet) do
      {:ok, height} ->
        height

      {:error, _} ->
        Logger.error("[#{DateTime.utc_now()}] Could not update block height from RPC module")
    end
  end

  defp fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number, :mainnet) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        Logger.error("Could not fetch block #{number} from RPC module")
        :error
    end
  end
end
