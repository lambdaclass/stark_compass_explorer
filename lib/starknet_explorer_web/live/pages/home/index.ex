defmodule StarknetExplorerWeb.HomeLive.Index do
  alias StarknetExplorerWeb.Component.TransactionsPerSecond, as: TPSComponent
  alias StarknetExplorerWeb.Utils
  use Phoenix.Component
  use StarknetExplorerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(), :load_blocks, 100, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: [],
       block_height: "Loading..."
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 justify-center items-center mt-16 lg:mt-10">
      <h1>Welcome to</h1>
      <h2>Madara Starknet Explorer</h2>
    </div>
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="mx-auto max-w-7xl grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-5 my-5">
      <div class="flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5">
        <img src={~p"/images/box.svg"} />
        <div class="text-sm">
          <div>Blocks Height</div>
          <div><%= assigns.block_height %></div>
        </div>
      </div>
      <div class="relative flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5">
        <img id="tps" class="absolute top-2 right-2 w-5 h-5" src={~p"/images/help-circle.svg"} />
        <img src={~p"/images/zap.svg"} />
        <div class="text-sm">
          <div>TPS</div>
          <div>
            <%= live_render(@socket, TPSComponent,
              id: "tps-number",
              session: %{"network" => @network}
            ) %>
          </div>
        </div>
      </div>
      <div class="flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5 relative">
        <div class="absolute top-2 right-2 gray-label text-[.7rem]">Mocked</div>
        <img src={~p"/images/code.svg"} />
        <div class="text-sm">
          <div>Classes</div>
          <div>4,536</div>
        </div>
      </div>
      <div class="flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5 relative">
        <div class="absolute top-2 right-2 gray-label text-[.7rem]">Mocked</div>
        <img src={~p"/images/message-square.svg"} />
        <div class="text-sm">
          <div>Messages</div>
          <div>905,510</div>
        </div>
      </div>
      <div class="flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5 relative">
        <div class="absolute top-2 right-2 gray-label text-[.7rem]">Mocked</div>
        <img src={~p"/images/file.svg"} />
        <div class="text-sm">
          <div>Contracts</div>
          <div>1,525,792</div>
        </div>
      </div>
      <div class="flex items-start gap-3 bg-container pt-7 pb-5 px-4 md:px-5 relative">
        <div class="absolute top-2 right-2 gray-label text-[.7rem]">Mocked</div>
        <img src={~p"/images/calendar.svg"} />
        <div class="text-sm">
          <div>Events</div>
          <div>2.15</div>
        </div>
      </div>
    </div>
    <div class="mx-auto max-w-7xl grid md:grid-cols-3 gap-5 mb-10" phx-hook="Stats" id="stats_table">
      <div class="pt-5 bg-container relative">
        <div class="absolute top-2 right-2 gray-label text-sm">Mocked</div>
        <div class="ml-7 text-gray-500">Transactions</div>
        <div id="transactions-chart"></div>
      </div>
      <div class="pt-5 bg-container relative">
        <div class="absolute top-2 right-2 gray-label text-sm">Mocked</div>
        <div class="ml-7 text-gray-500">Transaction Fees</div>
        <div id="fees"></div>
      </div>
      <div class="pt-5 bg-container relative">
        <div class="absolute top-2 right-2 gray-label text-sm">Mocked</div>
        <div class="ml-7 text-gray-500">TVL</div>
        <div id="tvl"></div>
      </div>
    </div>
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
                  to: ~p"/#{assigns.network}/block/#{block["block_number"]}"
                ) %>
              </div>
              <div class="col-span-2">
                <div class="list-h">Block Hash</div>
                <div class="copy-container" id={"copy-block-#{block["block_number"]}"} phx-hook="Copy">
                  <div class="relative">
                    <%= live_redirect(Utils.shorten_block_hash(block["block_hash"]),
                      to: ~p"/#{assigns.network}/block/#{block["block_hash"]}",
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
                        to: ~p"/#{assigns.network}/transactions/#{transaction["transaction_hash"]}",
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
    latest_block = Utils.get_latest_block_with_transactions(socket.assigns.network)

    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(socket.assigns.network),
       latest_block: latest_block,
       block_height: latest_block |> hd |> Map.get("block_number")
     )}
  end
end
