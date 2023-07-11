defmodule StarknetExplorerWeb.HomeLive.Index do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 justify-center items-center">
      <h1>Welcome to</h1>
      <h2>Starknet Explorer</h2>
    </div>
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="mx-auto max-w-7xl grid lg:grid-cols-2 lg:gap-5 xl:gap-16 mt-16">
      <div>
        <div class="table-header">
          <div class="table-title">Latest Blocks</div>
          <a href="/blocks" class="text-gray-300 hover:text-white transition-all duration-300">
            <div class="flex gap-2 items-center">
              <div>View all blocks</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </a>
        </div>
        <div class="table-block">
          <div class="grid-6 table-th">
            <div>Number</div>
            <div class="col-span-2">Block Hash</div>
            <div class="col-span-2">Status</div>
            <div>Age</div>
          </div>
          <%= for block <- Enum.take(@blocks, 15) do %>
            <div id={"block-#{block["block_number"]}"} class="grid-6 custom-list-item">
              <div>
                <div class="list-h">Number</div>
                <%= live_redirect(to_string(block["block_number"]),
                  to: "/block/#{block["block_number"]}"
                ) %>
              </div>
              <div class="col-span-2">
                <div class="list-h">Block Hash</div>
                <div class="copy-container" id={"copy-block-#{block["block_number"]}"} phx-hook="Copy">
                  <div class="relative">
                    <%= live_redirect(Utils.shorten_block_hash(block["block_hash"]),
                      to: "/block/#{block["block_hash"]}",
                      class: "text-hover-blue",
                      title: block["block_hash"]
                    ) %>
                    <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                      <div class="relative">
                        <img
                          class="copy-btn copy-text w-4 h-4"
                          src={~p"/images/copy.svg"}
                          data-text={block["block_hash"]}
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
                <div class="list-h">Status</div>
                <div>
                  <span class={"#{if block["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if block["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if block["status"] == "PENDING", do: "pink-label"}"}>
                    <%= block["status"] %>
                  </span>
                </div>
              </div>
              <div>
                <div class="list-h">Age</div>
                <%= Utils.get_block_age(block) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <div>
        <div class="table-header">
          <div class="table-title">Latest Transactions</div>
          <a href="/transactions" class="text-gray-300 hover:text-white transition-all duration-300">
            <div class="flex gap-2 items-center">
              <div>View all transactions</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </a>
        </div>
        <div class="table-block">
          <div class="grid-7 table-th">
            <div class="col-span-2">Transaction Hash</div>
            <div class="col-span-2">Type</div>
            <div class="col-span-2">Status</div>
            <div>Age</div>
          </div>
          <%= for block <- @latest_block do %>
            <%= for {transaction, idx} <- Enum.take(Enum.with_index(block["transactions"]), 15) do %>
              <div id={"transaction-#{idx}"} class="grid-7 custom-list-item">
                <div class="col-span-2">
                  <div class="list-h">Transaction Hash</div>
                  <div class="copy-container" id={"copy-transaction-#{idx}"} phx-hook="Copy">
                    <div class="relative">
                      <%= live_redirect(Utils.shorten_block_hash(transaction["transaction_hash"]),
                        to: "/transactions/#{transaction["transaction_hash"]}",
                        class: "text-hover-blue"
                      ) %>
                      <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                        <div class="relative">
                          <img
                            class="copy-btn copy-text w-4 h-4"
                            src={~p"/images/copy.svg"}
                            data-text={transaction["transaction_hash"]}
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
                    <span class={"#{if transaction["type"] == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
                      <%= transaction["type"] %>
                    </span>
                  </div>
                </div>
                <div class="col-span-2">
                  <div class="list-h">Status</div>
                  <div>
                    <span class={"#{if block["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if block["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if block["status"] == "PENDING", do: "pink-label"}"}>
                      <%= block["status"] %>
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
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(),
       latest_block: Utils.get_latest_block_with_transactions()
     )}
  end
end
