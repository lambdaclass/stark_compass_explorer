defmodule StarknetExplorerWeb.EventIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Events</h2>
      </div>
      <div class="table-block">
        <ul class="transactions-grid table-th">
          <li class="col-span-2" scope="col">Identifier</li>
          <li class="col-span-2" scope="col">Block Number</li>
          <li class="col-span-2" scope="col">Transaction Hash</li>
          <li class="col-span-2" scope="col">Name</li>
          <li class="col-span-2" scope="col">From Address</li>
          <li class="col-span-2" scope="col">Age</li>
        </ul>
        <div id="classes">
          <%= for idx <- 0..30 do %>
            <ul id={"message-#{idx}"} class="transactions-grid border-t border-gray-600">
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac_1"
                  ),
                  to: "/events/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">98369</li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac"
                  ),
                  to:
                    "/transactions/0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">transfer</li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
                  ),
                  to: "/contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-hover-blue"
                ) %>
              </li>
              <li class="col-span-2" scope="row">7min</li>
            </ul>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_events, [])

    {:ok, assign(socket, events: [])}
  end

  @impl true
  def handle_info(:load_events, socket) do
    # TODO: Fetch this from the db
    {:noreply, assign(socket, events: [])}
  end
end
