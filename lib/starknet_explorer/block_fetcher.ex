defmodule StarknetExplorer.BlockFetcher do
  use GenServer
  require Logger
  alias StarknetExplorer.{Rpc, BlockFetcher, Block, Class}
  defstruct [:block_height, :latest_block_fetched]
  @fetch_interval 300
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    state = %BlockFetcher{
      # The actual chain block-height
      block_height: fetch_block_height(),
      # Highest block number stored on the DB
      latest_block_fetched: StarknetExplorer.Block.highest_fetched_block_number()
    }

    Process.send_after(self(), :fetch_and_store, @fetch_interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:fetch_and_store, state = %BlockFetcher{}) do
    # Try to fetch the new height, else keep the current one.
    curr_height =
      case fetch_block_height() do
        height when is_integer(height) -> height
        _ -> state.block_height
      end

    # If the db is 10 blocks behind,
    # fetch a new block, else do nothing.
    if curr_height + 10 >= state.latest_block_fetched do
      case fetch_block(state.latest_block_fetched + 1) do
        {:ok, block = %{"block_number" => new_block_number}} ->
          {:ok, state_updates} = Rpc.get_state_update(new_block_number)
          deployed_contracts = state_updates["state_diff"]["deployed_contracts"]
          declared_classes = state_updates["state_diff"]["declared_classes"]

          declared_classes =
            Enum.map(declared_classes, fn %{"class_hash" => class_hash} ->
              {:ok, class} = Rpc.get_class(new_block_number, class_hash)

              Map.put(class, "hash", class_hash)
              |> Map.put("block_number", new_block_number)
              |> Map.put("declared_at", block["timestamp"])
            end)

          :ok = Block.insert_from_rpc_response(block)
          :ok = Class.insert_from_rpc_response(declared_classes)
          Logger.info("Inserted new block: #{new_block_number}")
          Process.send_after(self(), :fetch_and_store, @fetch_interval)
          {:noreply, %{state | block_height: curr_height, latest_block_fetched: new_block_number}}

        :error ->
          {:noreply, state}
      end
    end
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end

  defp fetch_block_height() do
    case Rpc.get_block_height() do
      {:ok, height} ->
        height

      {:error, _} ->
        Logger.error("[#{DateTime.utc_now()}] Could not update block height from RPC module")
    end
  end

  defp fetch_block(number) when is_integer(number) do
    case Rpc.get_block_by_number(number) do
      {:ok, block} ->
        {:ok, block}

      {:error, _} ->
        Logger.error("Could not fetch block #{number} from RPC module")
        :error
    end
  end
end
