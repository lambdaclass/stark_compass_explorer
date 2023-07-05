defmodule StarknetExplorer.BlockFetcher do
  use GenServer
  require Logger
  alias StarknetExplorer.{Rpc, BlockFetcher, Block}
  defstruct [:block_height, :latest_block_fetched]
  # 1 minute
  # @fetch_interval 1000 * 60
  @fetch_interval 1000
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %BlockFetcher{
      # The actual chain block-height
      block_height: fetch_block_height(),
      # Latest fetched (i.e it's in the db) block's height
      latest_block_fetched: StarknetExplorer.Block.highest_fetched_block_number()
    }

    Process.send_after(self(), :fetch_and_store, @fetch_interval)
    {:ok, state}
  end

  defp fetch_block_height() do
    case Rpc.get_block_height() do
      {:ok, height} ->
        height

      {:error, _} ->
        Logger.error(
          "[#{DateTime.utc_now()}] Could not fetch an update block height from RPC module"
        )
    end
  end

  defp fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        Logger.error("[#{DateTime.utc_now()}] Could not fetch block #{number} from RPC module")
        :error
    end
  end

  @impl true
  def handle_info(:fetch_and_store, state = %BlockFetcher{}) do
    # Try to fetch the new height, else keep the current one.
    curr_height =
      case fetch_block_height() do
        height when is_integer(height) -> height
        _ -> state.block_height
      end

    # If we're 10 blocks in deep, fetch a new block, else do nothing.
    if curr_height + 10 >= state.latest_block_fetched do
      case fetch_block(state.latest_block_fetched + 1) do
        {:ok, block = %{"block_number" => new_block_number}} ->
          IO.inspect(block, label: Theblock)
          :ok = Block.insert_from_rpc_response(block)
          Logger.info("[#{DateTime.utc_now()}] Inserted new block: #{new_block_number}")
          Process.send_after(self(), :fetch_and_store, @fetch_interval)
          {:noreply, %{state | block_height: curr_height, latest_block_fetched: new_block_number}}

        :error ->
          {:noreply, state}
      end
    end
  end
end
