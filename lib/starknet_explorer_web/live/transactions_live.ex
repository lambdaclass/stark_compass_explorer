defmodule StarknetExplorerWeb.TransactionsLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils

  def render(assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <th>Transaction Hash</th>
          <th>Type</th>
          <th>Status</th>
          <th>Age</th>
        </tr>
      </thead>
      <tbody id="transactions">
        <%= for block <- @blocks_with_transactions do %>
          <%= for {transaction, idx} <- Enum.with_index(block["transactions"]) do %>
            <tr id={"transaction-#{idx}"}>
              <td><%= transaction["transaction_hash"] %></td>
              <td><%= transaction["type"] %></td>
              <td><%= block["status"] %></td>
              <td><%= get_block_age(block) %></td>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, [blocks_with_transactions: get_last_ten_blocks_with_transactions()])}
  end

  defp get_last_ten_blocks_with_transactions() do
    get_last_ten_block_numbers()
    |> Enum.map(fn block_number ->
      {:ok, block} = Rpc.get_block_by_number(block_number)
      block
    end)
  end

  defp get_last_ten_block_numbers() do
    {:ok, %{"block_number" => last_block_number}} = Rpc.get_latest_block()

    # I take a range of 10 blocks
    (last_block_number - 10)..last_block_number
    |> Enum.to_list()
  end

  defp get_block_age(block) do
    %{minutes: minutes, hours: hours, days: days} = DateUtils.calculate_time_difference(block["timestamp"])
    case days do
      0 -> case hours do
        0 -> "#{minutes} min"
        _ -> "#{hours} h"
      end
      _ -> "#{days} d"
    end
  end
end
