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
    <div class="mx-auto max-w-6xl grid grid-cols-2 gap-10 mt-10">
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
          <div class="table-th">
            <ul class="blocks-grid">
              <li scope="col">Number</li>
              <li class="col-span-2" scope="col">Block Hash</li>
              <li class="col-span-2" scope="col">Status</li>
              <li scope="col">Age</li>
            </ul>
          </div>
          <div id="blocks">
            <%= for block <- Enum.take(@blocks, 15) do %>
              <ul id={"block-#{block["block_number"]}"} class="blocks-grid border-t border-gray-600">
                <li scope="row">
                  <%= live_redirect(to_string(block["block_number"]),
                    to: "/block/#{block["block_number"]}",
                    class:
                      "text-se-lilac hover:text-se-hover-lilac transition-all duration-300 underline-none font-medium"
                  ) %>
                </li>
                <li class="col-span-2" scope="row">
                  <%= live_redirect(Utils.shorten_block_hash(block["block_hash"]),
                    to: "/block/#{block["block_hash"]}",
                    class:
                      "text-se-blue hover:text-se-hover-blue transition-all duration-300 underline-none font-medium",
                    title: block["block_hash"]
                  ) %>
                </li>
                <li class="col-span-2" scope="row"><%= block["status"] %></li>
                <li scope="row"><%= Utils.get_block_age(block) %></li>
              </ul>
            <% end %>
          </div>
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
          <div class="table-th">
            <ul class="transactions-grid">
              <li class="col-span-2" scope="col">Transaction Hash</li>
              <li class="col-span-2" scope="col">Type</li>
              <li class="col-span-2" scope="col">Status</li>
              <li scope="col">Age</li>
            </ul>
          </div>
          <div id="transactions">
            <%= for block <- @latest_block do %>
              <%= for {transaction, idx} <- Enum.take(Enum.with_index(block["transactions"]), 15) do %>
                <ul id={"transaction-#{idx}"} class="transactions-grid border-t border-gray-600">
                  <li class="col-span-2" scope="row">
                    <%= live_redirect(Utils.shorten_block_hash(transaction["transaction_hash"]),
                      to: "/transactions/#{transaction["transaction_hash"]}",
                      class:
                        "text-se-blue hover:text-se-hover-blue transition-all duration-300 underline-none font-medium"
                    ) %>
                  </li>
                  <li class="col-span-2" scope="row">
                    <%= transaction["type"] %>
                  </li>
                  <li class="col-span-2" scope="row"><%= block["status"] %></li>
                  <li scope="row"><%= Utils.get_block_age(block) %></li>
                </ul>
              <% end %>
            <% end %>
          </div>
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
