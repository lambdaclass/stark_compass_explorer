defmodule StarknetExplorerWeb.HomeLive.Index do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.{Block, Transaction}
  alias StarknetExplorerWeb.Utils
  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 justify-center items-center">
      <h1>Welcome to</h1>
      <h2>Starknet Explorer</h2>
    </div>
    <div class="mx-auto max-w-6xl grid lg:grid-cols-2 lg:gap-5 xl:gap-20 mt-16">
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
          <div class="blocks-grid table-th">
            <div scope="col">Number</div>
            <div class="col-span-2" scope="col">Block Hash</div>
            <div class="col-span-2" scope="col">Status</div>
            <div scope="col">Age</div>
          </div>
          <div id="blocks">
            <%= for block <- Enum.take(@blocks, 15) do %>
              <div
                id={"block-#{block.number}"}
                class="blocks-grid border-t first-of-type:border-t-0 lg:first-of-type:border-t border-gray-600"
              >
                <div scope="row">
                  <div class="list-h">Number</div>
                  <%= live_redirect(to_string(block.number),
                    to: "/block/#{block.number}",
                    class:
                      "text-se-lilac hover:text-se-hover-lilac transition-all duration-300 underline-none"
                  ) %>
                </div>
                <div class="col-span-2" scope="row">
                  <div class="list-h">Block Hash</div>
                  <div
                    class="copy-container flex gap-4 items-center"
                    id={"copy-block-#{block.number}"}
                    phx-hook="Copy"
                  >
                    <div class="relative">
                      <%= live_redirect(Utils.shorten_block_hash(block.hash),
                        to: "/block/#{block.hash}",
                        class:
                          "text-se-blue hover:text-se-hover-blue transition-all duration-300 underline-none",
                        title: block.hash
                      ) %>
                      <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                        <div class="relative">
                          <img
                            class="copy-btn copy-text w-4 h-4"
                            src={~p"/images/copy.svg"}
                            data-text={block.hash}
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
                <div class="col-span-2" scope="row">
                  <div class="list-h">Status</div>
                  <%= block.status %>
                </div>
                <div scope="row">
                  <div class="list-h">Age</div>
                  <%= Utils.get_block_age(block) %>
                </div>
              </div>
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
            <div class="transactions-grid">
              <div class="col-span-2" scope="col">Transaction Hash</div>
              <div class="col-span-2" scope="col">Type</div>
              <div class="col-span-2" scope="col">Status</div>
              <div scope="col">Age</div>
            </div>
          </div>
          <div id="transactions">
            <%= if not(is_nil(@latest_block)) do %>
              <%= for {transaction, idx} <- Enum.take(Enum.with_index(@latest_block.transactions), 15) do %>
                <div id={"transaction-#{idx}"} class="transactions-grid border-t border-gray-600">
                  <div class="col-span-2" scope="row">
                    <div class="list-h">Transaction Hash</div>
                    <div
                      class="copy-container flex gap-4 items-center"
                      id={"copy-transaction-#{idx}"}
                      phx-hook="Copy"
                    >
                      <div class="relative">
                        <%= live_redirect(Utils.shorten_block_hash(transaction.hash),
                          to: "/transactions/#{transaction.hash}",
                          class:
                            "text-se-blue hover:text-se-hover-blue transition-all duration-300 underline-none"
                        ) %>
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
                  <div class="col-span-2" scope="row">
                    <div class="list-h">Type</div>
                    <%= transaction.type %>
                  </div>
                  <div class="col-span-2" scope="row">
                    <div class="list-h">Status</div>
                    <%= @latest_block.status %>
                  </div>
                  <div scope="row">
                    <div class="list-h">Age</div>
                    <%= Utils.get_block_age(@latest_block) %>
                  </div>
                </div>
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
    [latest_block | blocks] = Block.latest_n_blocks_with_txs(15)

    {:noreply,
     assign(socket,
       blocks: blocks,
       latest_block: latest_block
     )}
  end
end
