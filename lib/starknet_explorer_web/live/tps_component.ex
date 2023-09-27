defmodule StarknetExplorerWeb.Component.TransactionsPerSecond do
  use StarknetExplorerWeb, :live_view
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
      |> assign(tx_per_second: calculate_tps(network))

    {:ok, socket}
  end

  defp calculate_tps(network) do
    result = StarknetExplorer.IndexCache.latest_blocks(network)

    if length(result) < 2 do
      0
    else
      [current_block | [previous_block | _]] = result
      curr_block_time = current_block.timestamp - previous_block.timestamp

      tx_amount = Enum.count(current_block.transactions)

      safe_div(tx_amount, curr_block_time) |> :erlang.float_to_binary(decimals: 2)
    end
  end

  defp safe_div(x, y) when is_number(x) and is_number(y) and y > 0, do: x / y
  defp safe_div(_, _), do: 0.0
end
