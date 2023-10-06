defmodule StarknetExplorerWeb.ContractIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header !justify-start gap-5">
        <h2>Contracts</h2>
        <span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="table-block">
        <div class="grid-4 table-th">
          <div>Contract Address</div>
          <div>Type</div>
          <div>Class Hash</div>
          <div>Deployed At</div>
        </div>
        <div id="contracts">
          <%= for idx <- 0..30 do %>
            <div id={"contract-#{idx}"} class="grid-4 custom-list-item">
              <div>
                <div class="list-h">Contract Address</div>
                <%= Utils.shorten_block_hash(
                  "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                ) %>
              </div>
              <div>
                <div class="list-h">Type</div>
                <div><span class="pink-label">PROXY ACCOUNT</span></div>
              </div>
              <div>
                <div class="list-h">Class Hash</div>
                <%= Utils.shorten_block_hash(
                  "0x025ec026985a3bf9d0cc1fe17326b245dfdc3ff89b8fde106542a3ea56c5a918"
                ) %>
              </div>
              <div>
                <div class="list-h">Deployed At</div>
                <div>10 min</div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_contracts, [])

    {:ok, assign(socket, contracts: [])}
  end

  @impl true
  def handle_info(:load_contracts, socket) do
    # TODO: Fetch this from the db
    {:noreply, assign(socket, contracts: [])}
  end
end
