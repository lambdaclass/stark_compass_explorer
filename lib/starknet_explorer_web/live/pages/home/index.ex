defmodule StarknetExplorerWeb.HomeLive.Index do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :blocks, list_blocks())}
  end

  def render(assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <th>Number</th>
          <th>Block Hash</th>
          <th>Status</th>
          <th>Age</th>
          <th></th>
        </tr>
      </thead>
      <tbody id="blocks">
        <%= for block <- @blocks do %>
          <tr id={"block-#{block["block_number"]}"}>
            <td><%= block["block_number"] %></td>
            <td><%= block["block_hash"] %></td>
            <td><%= block["status"] %></td>
            <td><%= block["timestamp"] %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp get_latest_block_number() do
    {:ok, latest_block} = Rpc.get_latest_block()
    latest_block["block_number"]
  end

  defp list_blocks() do
    list_blocks(get_latest_block_number(), 15, [])
  end

  defp list_blocks(_block_number, 0, acc) do
    acc
  end

  defp list_blocks(block_number, remaining, acc) do
    {:ok, block} = Rpc.get_block_by_number(block_number)
    prev_block_number = block_number - 1
    list_blocks(prev_block_number, remaining - 1, [block | acc])
  end
end
