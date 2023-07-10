defmodule StarknetExplorerWeb.MessageIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Messages</h2>
      </div>
      <div class="table-block">
        <ul class="transactions-grid table-th">
          <li class="col-span-2" scope="col">Identifier</li>
          <li class="col-span-2" scope="col">Message Hash</li>
          <li class="col-span-2" scope="col">Direction</li>
          <li class="col-span-2" scope="col">Type</li>
          <li class="col-span-2" scope="col">From Address</li>
          <li class="col-span-2" scope="col">To Address</li>
          <li class="col-span-2" scope="col">Transaction Hash</li>
          <li class="col-span-2" scope="col">Age</li>
        </ul>
        <div id="classes">
          <%= for idx <- 0..30 do %>
            <ul id={"message-#{idx}"} class="transactions-grid border-t border-gray-600">
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                  ),
                  to: "/messages/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0xd8eda3e8962aa40cab490a11bd6e07e4f2a4b3fd276a6521c9fa2fc39165346b"
                  ),
                  to: "/messages/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">L2 -> L1</li>
              <li class="col-span-2" scope="row">CONSUMED_ON_L1</li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
                  ),
                  to: "/contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash("0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419"),
                  to:
                    "/etherscan_contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0xaffd6222cce4c2f43286d01c4f4ab2c6ce73421f0233484557a011d1485499e1"
                  ),
                  to:
                    "/etherscan_transactions/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">5 min</li>
            </ul>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_messages, [])

    {:ok, assign(socket, messages: [])}
  end

  @impl true
  def handle_info(:load_messages, socket) do
    # TODO: Fetch this from the db
    {:noreply, assign(socket, messages: [])}
  end
end
