defmodule StarknetExplorerWeb.BlockDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  defp block_detail_header(assigns) do
    ~H"""
    <h2>Block <span class="font-semibold">#<%= @block["block_number"] %></span></h2>
    <div class="flex gap-5 border-b border-b-gray-600 my-5">
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.view == "overview", do: "border-b-se-blue", else: "border-b-transparent"}"}
        id="overviewTab"
        phx-hook="Tabs"
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.view == "transactions", do: "border-b-se-blue", else: "border-b-transparent"}"}
        id="transactionsTab"
        phx-hook="Tabs"
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
    </div>
    """
  end

  def mount(_params = %{"number_or_hash" => param}, _session, socket) do
    {:ok, block} =
      case num_or_hash(param) do
        :hash ->
          Rpc.get_block_by_hash(param)

        :num ->
          {num, ""} = Integer.parse(param)
          Rpc.get_block_by_number(num)
      end

    assigns = [
      block: block,
      view: "overview"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto bg-[#232331] p-5 rounded-md">
      <%= block_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{block: block, view: "transactions"}) do
    ~H"""
    <table>
      <tbody id="transactions">
        <h1>Block Transactions</h1>
        <%= for _transaction = %{"transaction_hash" => hash, "type" => type, "version" => version} <- @block["transactions"] do %>
          <table>
            <thead>
              <tr>
                <th>Type</th>
                <th>Version</th>
                <th>Hash</th>
              </tr>
              <tbody>
                <tr>
                  <td><%= type %></td>
                  <td><%= version %></td>
                  <td><%= hash |> Utils.shorten_block_hash() %></td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  # TODO:
  # Do not hardcode:
  # - Total Execeution Resources
  # - Gas Price
  def render_info(assigns = %{block: _block, view: "overview"}) do
    ~H"""
    <div class="grid grid-cols-4 gap-10 px-3">
      <div>Block Hash</div>
      <div class="col-span-3"><%= @block["block_hash"] %></div>
      <div>Block Status</div>
      <div class="col-span-3"><%= @block["status"] %></div>
      <div>State Root</div>
      <div class="col-span-3"><%= @block["new_root"] %></div>
      <div>Parent Hash</div>
      <div class="col-span-3"><%= @block["parent_hash"] %></div>
      <div>Sequencer Address</div>
      <div class="col-span-3"><%= @block["sequencer_address"] %></div>
      <div>Gas Price</div>
      <div class="col-span-3"><%= "0.000000017333948464 ETH" %></div>
      <div>Total execution resources</div>
      <div class="col-span-3"><%= 543_910 %></div>
      <div>Timestamp</div>
      <div>
        <%= @block["timestamp"]
        |> DateTime.from_unix()
        |> then(fn {:ok, time} -> time end)
        |> Calendar.strftime("%c") %> UTC
      </div>
    </div>
    """
  end

  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
