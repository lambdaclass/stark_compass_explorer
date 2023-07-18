defmodule StarknetExplorerWeb.EventIndexLive do
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
        <h2>Events</h2>
        <span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Identifier</div>
          <div>Block Number</div>
          <div>Transaction Hash</div>
          <div>Name</div>
          <div>From Address</div>
          <div>Age</div>
        </div>
        <%= for idx <- 0..30 do %>
          <div id={"message-#{idx}"} class="grid-6 custom-list-item">
            <div>
              <div class="list-h">Identifier</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac_1"
                ),
                to: ~p"/#{@network}/events/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                class: "text-hover-blue"
              ) %>
            </div>
            <div>
              <div class="list-h">Block Number</div>
              <div>98369</div>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac"
                ),
                to:
                  ~p"/#{@network}/transactions/0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac",
                class: "text-hover-blue"
              ) %>
            </div>
            <div>
              <div class="list-h">Name</div>
              <div><span class="violet-label">transfer</span></div>
            </div>
            <div>
              <div class="list-h">From Address</div>
              <%= live_redirect(
                Utils.shorten_block_hash(
                  "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
                ),
                to: ~p"/#{@network}/contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                class: "text-hover-blue"
              ) %>
            </div>
            <div>
              <div class="list-h">Age</div>
              <div>7min</div>
            </div>
          </div>
        <% end %>
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
