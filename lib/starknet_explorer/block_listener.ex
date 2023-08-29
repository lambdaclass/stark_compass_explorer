defmodule StarknetExplorer.BlockListener do
  use GenServer, restart: :temporary
  require Logger
  alias StarknetExplorer.{Rpc, BlockListener, Block, BlockUtils}
  defstruct [:latest_block_number]
  @fetch_latest_interval 100
  @moduledoc """
  Module dedicated to listen for block height updates,
  when a new block is available, this process
  will try and fetch it from the RPC provider.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    block_height = BlockUtils.block_height()

    state = %BlockListener{
      latest_block_number: block_height
    }

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    Logger.debug("Listener enabled")
    {:ok, state}
  end

  def handle_info(:fetch_latest, state = %BlockListener{}) do
    new_height = BlockUtils.block_height()
    highest_fetched = state.latest_block_number

    state =
      if new_height > highest_fetched do
        case BlockUtils.fetch_and_store(highest_fetched + 1) do
          :ok ->
            %{state | latest_block_number: highest_fetched}

          {:error, err} ->
            Logger.error(
              "[Block Listener] Error fetching latest block: #{inspect(err)}, retrying..."
            )

            state
        end
      else
        state
      end

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    {:noreply, state}
  end

  def handle_info(:fetch_backwards, state = %BlockListener{}) do
    to_fetch = state.latest_block_number - 1

    state =
      case Rpc.get_block_by_number(to_fetch, :gateway_mainnet) do
        {:ok, block} ->
          Logger.info("Block #{to_fetch} fetched succesfully!")
          %{state | latest_block_number: to_fetch}

        {:error, err} ->
          Logger.error("Error fetching block number #{to_fetch}: #{inspect(err)}")
          state
      end

    Process.send_after(self(), :fetch_latest, @fetch_backwards_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end
end
