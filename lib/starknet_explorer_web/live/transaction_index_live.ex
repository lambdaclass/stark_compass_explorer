defmodule StarknetExplorerWeb.TransactionIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Transactions</h2>
      </div>
      <div class="table-block">
        <div class="grid-7 table-th">
          <div class="col-span-2">Transaction Hash</div>
          <div class="col-span-2">Type</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <div id="transactions">
          <%= for block <- @latest_block do %>
            <%= for {transaction, idx} <- Enum.with_index(Enum.take(block.transactions, 30)) do %>
              <div id={"transaction-#{idx}"} class="grid-7 custom-list-item">
                <div class="col-span-2">
                  <div class="list-h">Transaction Hash</div>
                  <div class="copy-container" id={"copy-tsx-#{idx}"} phx-hook="Copy">
                    <div class="relative">
                      <a
                        href={
                          Utils.network_path(
                            @network,
                            "transactions/#{transaction.hash}"
                          )
                        }
                        class="text-hover-blue"
                      >
                        <span><%= Utils.shorten_block_hash(transaction.hash) %></span>
                      </a>
                      <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                        <div class="relative">
                          <img
                            class="copy-btn copy-text w-4 h-4"
                            src={~p"/images/copy.svg"}
                            data-text={transaction.hash}
                          />
                          <img
                            class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                            src={~p"/images/check-square.svg"}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="col-span-2">
                  <div class="list-h">Type</div>
                  <div>
                    <span class={"#{if transaction.type == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
                      <%= transaction.type %>
                    </span>
                  </div>
                </div>
                <div class="col-span-2">
                  <div class="list-h">Status</div>
                  <div>
                    <span class={"#{if block.status == "ACCEPTED_ON_L2", do: "green-label"} #{if block.status == "ACCEPTED_ON_L1", do: "blue-label"} #{if block.status == "PENDING", do: "pink-label"}"}>
                      <%= block.status %>
                    </span>
                  </div>
                </div>
                <div>
                  <div class="list-h">Age</div>
                  <%= Utils.get_block_age(block) %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(), :load_blocks, 100, [])

    {:ok,
     assign(socket,
       latest_block: []
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       latest_block: Data.latest_block_with_transactions(socket.assigns.network)
     )}
  end
end
