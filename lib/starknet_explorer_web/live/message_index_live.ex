defmodule StarknetExplorerWeb.MessageIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="max-w-7xl mx-auto">
      <div class="table-header !justify-start gap-5">
        <h2>Messages</h2>
        <span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="table-block">
        <div class="grid-9 table-th">
          <div>Identifier</div>
          <div>Message Hash</div>
          <div>Direction</div>
          <div class="col-span-2">Type</div>
          <div>From Address</div>
          <div>To Address</div>
          <div>Transaction Hash</div>
          <div>Age</div>
        </div>
        <%= for idx <- 0..30 do %>
          <div id={"message-#{idx}"} class="grid-9 custom-list-item">
            <div>
              <div class="list-h">Identifier</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                ),
                to: "/messages/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                class: "text-hover-blue"
              ) %>
            </div>
            <div>
              <div class="list-h">Message Hash</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0xd8eda3e8962aa40cab490a11bd6e07e4f2a4b3fd276a6521c9fa2fc39165346b"
                ),
                to: "/messages/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
              ) %>
            </div>
            <div>
              <div class="list-h">Direction</div>
              <div><span class="green-label">L2</span>-> <span class="blue-label">L1</span></div>
            </div>
            <div class="col-span-2">
              <div class="list-h">Type</div>
              <div class="violet-label">CONSUMED_ON_L1</div>
            </div>
            <div>
              <div class="list-h">From Address</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
                ),
                to: "/contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
              ) %>
            </div>
            <div>
              <div class="list-h">To Address</div>
              <%= live_redirect(
                Utils.shorten_block_hash("0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419"),
                to:
                  "/etherscan_contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
              ) %>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0xaffd6222cce4c2f43286d01c4f4ab2c6ce73421f0233484557a011d1485499e1"
                ),
                to:
                  "/etherscan_transactions/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                class: "text-hover-blue"
              ) %>
            </div>
            <div>
              <div class="list-h">Age</div>
              <div>5 min</div>
            </div>
          </div>
        <% end %>
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
