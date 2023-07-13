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
    {:ok, latest = %{"block_number" => height, "timestamp" => curr_block_timestamp}} =
      Rpc.get_latest_block()

    {:ok, _prev_block = %{"timestamp" => prev_block_time}} = Rpc.get_block_by_number(height - 1)

    curr_block_time = curr_block_timestamp - prev_block_time

    tx_amount = Enum.count(latest["transactions"])

    {:noreply,
     assign(socket,
       tx_per_second: (tx_amount / curr_block_time) |> :erlang.float_to_binary(decimals: 2)
     )}
  end
end
