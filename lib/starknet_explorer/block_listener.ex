defmodule StarknetExplorer.BlockListener do
  use GenServer, restart: :temporary
  require Logger
  alias StarknetExplorer.{BlockListener, BlockUtils}
  defstruct [:latest_block_number]
  @fetch_latest_interval :timer.seconds(1)
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
    Logger.info("Listener enabled")
    {:ok, state}
  end

  def handle_info(:fetch_latest, state = %BlockListener{}) do
    new_height = BlockUtils.block_height()
    new_blocks? = new_height > state.latest_block_number

    state =
      maybe_fetch_another(new_blocks?, state)

    Process.send_after(self(), :fetch_latest, @fetch_latest_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:stop, _) do
    Logger.info("Stopping BlockFetcher")
    {:stop, :normal, :ok}
  end

  defp maybe_fetch_another(new_blocks?, state = %BlockListener{}) when new_blocks? do
    next_to_fetch = state.latest_block_number + 1

    case BlockUtils.fetch_and_store(next_to_fetch) do
      {:ok, _} ->
        Logger.info("New block stored: #{next_to_fetch}")
        %{state | latest_block_number: next_to_fetch}

      {:error, err} ->
        Logger.error("[Block Listener] Error fetching latest block: #{inspect(err)}, retrying...")

        state
    end
  end

  defp maybe_fetch_another(new_blocks?, state) when not new_blocks?, do: state
end
