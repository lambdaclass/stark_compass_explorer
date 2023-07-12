defmodule StarknetExplorerWeb.TPSComponent do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  @impl true
  def render(assigns = %{tx_per_second: nil}) do
    ~H"""
    Loading...
    """
  end

  def render(assigns = %{tx_per_second: _}) do
    ~H"""
    <%= assigns.tx_per_second %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(), :calculate_tps, 100, [])

    {:ok,
     assign(socket,
       tx_per_second: nil
     )}
  end

  @impl true
  def handle_info(:calculate_tps, socket) do
    # Fetch the current block height
    # and set a lower bound.
    {:ok, block_height} = StarknetExplorer.Rpc.get_block_height()
    block_lower_bound = block_height - 100

    # Fetch 100 blocks
    # below the block height.
    blocks =
      block_lower_bound..block_height
      |> Enum.map(fn block ->
        Task.async(fn ->
          Rpc.get_block_by_number(block)
        end)
      end)
      |> Task.await_many()
      |> Enum.map(fn {:ok, block} -> block end)

    # Calculate the average amount
    # of transactions per block.
    avg_tx_per_block =
      blocks
      # Sum number of txs per block
      |> Enum.reduce(0, fn
        block, txs_in_total -> length(block["transactions"]) + txs_in_total
      end)
      # Divide to get average.
      |> then(fn total_txs -> total_txs / 100 end)

    # Calculate average block time.
    #  block time = (current block timestamp) - (previous block timestamp)
    block_time_avg =
      blocks
      # Sort blocks by block number
      |> Enum.sort_by(fn %{"block_number" => block_number} -> block_number end, :asc)
      # Group each 2 blocks, to then calculate block time
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [%{"timestamp" => time_1}, %{"timestamp" => time_2}] -> time_2 - time_1 end)
      |> Enum.sum()
      |> then(fn block_time_total -> block_time_total / 100 end)

    # Tx per second = (average number of tx per block) / (average block time)
    tx_per_second =
      (avg_tx_per_block / block_time_avg)
      |> :erlang.float_to_binary(decimals: 2)

    {:noreply,
     assign(socket,
       tx_per_second: tx_per_second
     )}
  end
end
