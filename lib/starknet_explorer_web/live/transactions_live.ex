defmodule StarknetExplorerWeb.TransactionsLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  def render(assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <th>Transaction Hash</th>
          <th>Type</th>
          <th>Status</th>
          <th>Age</th>
          <th></th>
        </tr>
      </thead>
      <tbody id="transactions">
        <%= for block <- @blocks_with_transactions do %>
          <%= for {transaction, idx} <- Enum.with_index(block["transactions"]) do %>
            <tr id={"transaction-#{idx}"}>
              <td><%= transaction["transaction_hash"] %></td>
              <td><%= transaction["type"] %></td>
              <td><%= block["status"] %></td>
              <td><%= block["age"] %></td>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
    """
  end

  def mount(_params, _session, socket) do
    blocks_with_transactions =
      get_transactions_from_last_ten_blocks()
      |> Enum.map(fn block -> Map.put(block, "age", get_block_age(block)) end)

    {:ok, assign(socket, [blocks_with_transactions: blocks_with_transactions])}
  end

  defp get_transactions_from_last_ten_blocks() do
    for block_number <- get_last_ten_block_numbers() do
      {:ok, block} = StarknetExplorer.Rpc.get_block_by_number(block_number)
      block
    end
  end

  defp get_last_ten_block_numbers() do
    {:ok, %{"block_number" => last_block_number}} = StarknetExplorer.Rpc.get_last_block()

    # I take a range of 10 blocks
    (last_block_number - 10)..last_block_number
    |> Enum.to_list()
  end


  defp get_block_age(block) do
    %{minutes: minutes, hours: hours, days: days} = StarknetExplorer.DateUtils.calculate_time_difference(block["timestamp"])
    case days do
      0 -> case hours do
        0 -> "#{minutes} min"
        _ -> "#{hours} h"
      end
      _ -> "#{days} d"
    end
  end
end
