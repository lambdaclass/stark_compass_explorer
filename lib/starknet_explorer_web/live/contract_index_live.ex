defmodule StarknetExplorerWeb.ContractIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="table-header">
        <h2>Contracts</h2>
      </div>
      <div class="table-block">
        <ul class="transactions-grid table-th">
          <li class="col-span-2" scope="col">Contract Address</li>
          <li class="col-span-2" scope="col">Type</li>
          <li class="col-span-2" scope="col">Class Hash</li>
          <li class="col-span-2" scope="col">Deployed At</li>
        </ul>
        <div id="contracts">
          <%= for idx <- 0..30 do %>
            <ul id={"contract-#{idx}"} class="transactions-grid border-t border-gray-600">
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                  ),
                  to: "/contracts/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-se-blue hover:text-se-hover-blue underline-none"
                ) %>
              </li>
              <li class="col-span-2" scope="row">PROXY ACCOUNT</li>
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x025ec026985a3bf9d0cc1fe17326b245dfdc3ff89b8fde106542a3ea56c5a918"
                  ),
                  to: "/classes/0x025ec026985a3bf9d0cc1fe17326b245dfdc3ff89b8fde106542a3ea56c5a918",
                  class: "text-se-blue hover:text-se-hover-blue underline-none"
                ) %>
              </li>
              <li class="col-span-2" scope="row">10 min</li>
            </ul>
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
