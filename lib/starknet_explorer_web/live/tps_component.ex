defmodule StarknetExplorerWeb.Component.TransactionsPerSecond do
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
  def mount(_params, _session = %{"network" => network}, socket) do
    Process.send_after(self(), :calculate_tps, 100, [])

    socket =
      socket
      |> assign(tx_per_second: nil)
      |> assign(:network, network)

    {:ok, socket}
  end

  @impl true
  def handle_info(:calculate_tps, socket) do
    # Fetch the current block height
    # and set a lower bound.
    {:ok, latest = %{"block_number" => height, "timestamp" => curr_block_timestamp}} =
      Rpc.get_latest_block_no_cache(socket.assigns.network)

    {:ok, _prev_block = %{"timestamp" => prev_block_time}} =
      Rpc.get_block_by_number(height - 1, socket.assigns.network)

    curr_block_time = curr_block_timestamp - prev_block_time

    tx_amount = Enum.count(latest["transactions"])

    {:noreply,
     assign(socket,
       tx_per_second: safe_div(tx_amount, curr_block_time) |> :erlang.float_to_binary(decimals: 2)
     )}
  end

  defp safe_div(x, y) when is_number(x) and is_number(y) and y > 0, do: x / y
  defp safe_div(_, _), do: 0.0
end
