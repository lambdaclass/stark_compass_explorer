defmodule StarknetExplorerWeb.Component.TransactionsPerSecond do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.Block

  @impl true
  def render(assigns = %{tx_per_second: _}) do
    ~H"""
    <%= assigns.tx_per_second %>
    """
  end

  @impl true
  def mount(_params, _session = %{"network" => network}, socket) do
    socket =
      socket
      |> assign(tx_per_second: calculate_tps(socket, network))

    {:ok, socket}
  end

  defp calculate_tps(socket, network) do
    [current_block, previous_block] = Block.latest_n_blocks_with_txs(2, network)
    curr_block_time = current_block.timestamp - previous_block.timestamp

    tx_amount = Enum.count(current_block.transactions)

    safe_div(tx_amount, curr_block_time) |> :erlang.float_to_binary(decimals: 2)
  end

  defp safe_div(x, y) when is_number(x) and is_number(y) and y > 0, do: x / y
  defp safe_div(_, _), do: 0.0
end
