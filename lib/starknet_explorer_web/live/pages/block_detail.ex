defmodule StarknetExplorerWeb.BlockDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  def mount(_params = %{"number_or_hash" => param}, _session, socket) do
    {:ok, block} =
      case num_or_hash(param) do
        :hash ->
          Rpc.get_block_by_hash(param)

        :num ->
          {num, ""} = Integer.parse(param)
          Rpc.get_block_by_number(num)
      end

    {:ok, assign(socket, :block, block)}
  end

  # TODO:
  # Do not hardcode:
  # - Total Execeution Resources
  # - Gas Price
  def render(assigns = %{block: _block}) do
    ~H"""
    <div class="flex justify-center items-center pt-14">
      <h1 class="text-white text-4xl font-mono">Block detail</h1>
    </div>
    <table>
      <thead>
        <ul>
          <li>Block Number <%= @block["block_number"] %></li>
          <li>Block Hash <%= @block["block_hash"] |> Utils.shorten_block_hash %></li>
          <li>Block Status <%= @block["status"] %></li>
          <li>State Root <%= @block["new_root"] |> Utils.shorten_block_hash  %></li>
          <li>Parent Hash <%= @block["parent_hash"] |> Utils.shorten_block_hash  %></li>
          <li>Sequencer Address <%= @block["sequencer_address"] %></li>
          <li>Gas Price <%= "0.000000017333948464 ETH" %></li>
          <li>Total execution resources <%= 543910 %></li>
          <li>
            Timestamp <%= @block["timestamp"]
            |> DateTime.from_unix()
            |> then(fn {:ok, time} -> time end) %> UTC
          </li>
        </ul>
      </thead>
      <tbody id="transactions">
        <h1>Block Transactions</h1>
        <%= for _transaction = %{"transaction_hash" => hash, "type" => type, "version" => version} <- @block["transactions"] do %>
        <table>
        <thead>
        <tr>
        <th> Type </th>
        <th> Version </th>
        <th> Hash </th>
        </tr>
        <tbody>
        <tr>
        <td> <%= type %> </td>
        <td> <%= version %> </td>
        <td> <%= hash |> Utils.shorten_block_hash %> </td>
        </tr>
        </tbody>
        </thead>
        </table>
        <% end %>
      </tbody>
    </table>
    """
  end
end
