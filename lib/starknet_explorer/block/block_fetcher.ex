defmodule StarknetExplorer.BlockFetcher.Worker do
  @fetch_interval 100
  alias StarknetExplorer.{BlockFetcher.Worker, BlockUtils}
  defstruct [:finish, :next_to_fetch]
  require Logger
  use GenServer, restart: :temporary

  @moduledoc """
  Module dedicated to fetch blocks on the range between 2 numbers
  (start and finish, where start > finish) so for example if start =
  10 and finish = 1, then this process will fetch blocks 10 down to 1.
  To use it, please call the
  StarknetExplorer.BlockFetcher.fetch_in_range/1 function instead of
  using this module directly.
  """

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

  @impl true
  def handle_info(:fetch, state = %Worker{}) do
    state =
      case BlockUtils.fetch_and_store(state.next_to_fetch) |> dbg do
        {:ok, _block} ->
          %{state | next_to_fetch: state.next_to_fetch - 1}

        {:error, err} ->
          Logger.error(
            "Error fetching block number #{state.next_to_fetch}: #{inspect(err)}, retrying..."
          )

          state
      end
      |> dbg

    maybe_fetch_another(state)

    {:noreply, state}
  end
  |> dbg

  defp maybe_fetch_another(%Worker{next_to_fetch: next, finish: last})
       when next < last,
       do: StarknetExplorer.BlockFetcher.stop_child(self())

  defp maybe_fetch_another(_),
    do: Process.send_after(self(), :fetch, @fetch_interval)
end
