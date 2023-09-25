defmodule StarknetExplorer.Blockchain.FetcherWorker do
  @fetch_interval 100
  alias StarknetExplorer.{Blockchain.FetcherWorker, BlockUtils}
  defstruct [:finish, :next_to_fetch, :network]
  require Logger
  use GenServer, restart: :temporary

  @moduledoc """
  Module dedicated to fetch blocks on the range between 2 numbers
  (start and finish, where start > finish) so for example if start =
  10 and finish = 1, then this process will fetch blocks 10 down to 1.
  """

  def start_link(args = [start: _start, finish: _finish, network: _network, name: name]) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl true
  def init(_args = [start: start, finish: finish, network: network, name: _name])
      when start > finish do
    state = %FetcherWorker{
      finish: finish,
      next_to_fetch: start,
      network: network
    }

    Process.send_after(self(), :fetch, @fetch_interval)

    Logger.info("Starting block fetcher from block: #{start} to #{finish}, in network #{network}")

    {:ok, state}
  end

  @impl true
  def handle_info(:fetch, state = %FetcherWorker{network: network}) do
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

  defp maybe_fetch_another(%FetcherWorker{next_to_fetch: next, finish: last})
       when next < last,
       do: StarknetExplorer.Blockchain.FetcherSupervisor.stop_child(self())

  defp maybe_fetch_another(_),
    do: Process.send_after(self(), :fetch, @fetch_interval)
end
