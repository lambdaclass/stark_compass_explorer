defmodule StarknetExplorer.BlockFetcher.Worker do
  @fetch_interval 100
  alias StarknetExplorer.{Rpc, BlockFetcher.Worker, BlockUtils}
  defstruct [:finish, :next_to_fetch, :network]
  require Logger
  use GenServer, restart: :temporary

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args = %{start: start, finish: finish}) when start > finish do
    state = %Worker{
      finish: finish,
      next_to_fetch: start
    }

    Process.send_after(self(), :fetch, @fetch_interval)

    Logger.info("Starting block fetcher from block: #{start} to #{finish}")

    {:ok, state}
  end

  def handle_info(:fetch, state = %Worker{}) do
    Process.send_after(self(), :fetch, @fetch_interval)
    IO.inspect(state, pretty: true, label: TheState)

    state =
      case BlockUtils.fetch_and_store(state.next_to_fetch) do
        {:ok, block} ->
          %{state | next_to_fetch: state.next_to_fetch - 1}

        {:error, err} ->
          Logger.error(
            "Error fetching block number #{state.next_to_fetch}: #{inspect(err)}, retrying..."
          )

          state
      end

    next_message =
      decide_next_message(state)

    Process.send_after(self(), next_message, @fetch_interval)

    {:noreply, state}
  end

  def handle_info(:stop, _) do
    Logger.info("Block fetcher finised!")
    {:stop, :normal, :ok}
  end

  defp decide_next_message(%Worker{next_to_fetch: next, finish: last}) when next < last,
    do: :stop

  defp decide_next_message(_), do: :fetch
end
