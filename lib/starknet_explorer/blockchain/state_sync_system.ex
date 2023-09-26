defmodule StarknetExplorer.Blockchain.StateSyncSystem do
  @moduledoc """
  State Sync System.
  """
  alias StarknetExplorer.{BlockUtils, Rpc, Blockchain.StateSyncSystem}
  defstruct [:newest_block_number, :network, :initial_block_height, :next_to_fetch]
  use GenServer
  require Logger
  @fetch_timer :timer.seconds(5)

  def start_link([network: _network, name: name] = arg) do
    GenServer.start_link(__MODULE__, arg, name: name)
  end

  ## Callbacks
  @impl true
  def init([network: network, name: _name] = _args) do
    block_height = BlockUtils.block_height(Atom.to_string(network))

    state = %StateSyncSystem{
      initial_block_height: block_height,
      newest_block_number: block_height,
      next_to_fetch: block_height,
      network: network
    }

    Process.send_after(self(), :listener, @fetch_timer)
    Process.send_after(self(), :fetcher, @fetch_timer)
    # Process.send_after(self(), :updater, @fetch_timer)
    Logger.info("State Sync System enabled for network #{network}.")
    {:ok, state}
  end

  @impl true
  def handle_info(:listener, state = %StateSyncSystem{network: network}) do
    {:ok, new_block_height} = Rpc.get_block_height_no_cache(network)
    new_blocks? = new_block_height > state.newest_block_number

    state =
      try_fetch(new_blocks?, state)

    Process.send_after(self(), :listener, @fetch_timer)
    {:noreply, state}
  end

  defp try_fetch(true, state = %StateSyncSystem{network: network}) do
    next_to_fetch = state.newest_block_number + 1

    case BlockUtils.fetch_and_store(next_to_fetch, network) do
      {:ok, _} ->
        Logger.info("New block stored: #{next_to_fetch}")
        %{state | newest_block_number: next_to_fetch}

      {:error, err} ->
        Logger.error("[Block Listener] Error fetching latest block: #{inspect(err)}, retrying...")

        state
    end
  end

  defp try_fetch(_new_blocks?, state), do: state

  @impl true
  def handle_info(:fetcher, state = %StateSyncSystem{network: network}) do
    state =
      case BlockUtils.fetch_and_store(state.next_to_fetch, network) do
        {:ok, _block} ->
          %{state | next_to_fetch: state.next_to_fetch - 1}

        {:error, err} ->
          Logger.error(
            "Error fetching block number #{state.next_to_fetch}: #{inspect(err)}, retrying..."
          )

          state
      end

    maybe_fetch_another(state)

    {:noreply, state}
  end

  # This means that we are fully syncd.
  defp maybe_fetch_another(%StateSyncSystem{next_to_fetch: -1} = _args), do: :ok

  defp maybe_fetch_another(_),
    do: Process.send_after(self(), :fetcher, @fetch_interval)
end
