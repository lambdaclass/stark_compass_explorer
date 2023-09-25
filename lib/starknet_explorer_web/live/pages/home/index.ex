defmodule StarknetExplorerWeb.HomeLive.Index do
  alias StarknetExplorerWeb.Component.TransactionsPerSecond, as: TPSComponent
  alias StarknetExplorerWeb.Utils
  use Phoenix.Component
  use StarknetExplorerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Process.send_after(self(), :load_blocks, 100, [])

    entities_count = %{
      message_count: "Loading...",
      events_count: "Loading...",
      transaction_count: "Loading..."
    }

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: [],
       block_height: "Loading...",
       entities_count: entities_count,
       transactions: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="flex flex-col gap-1 justify-center items-center mb-16">
      <h1>Madara Starknet Explorer</h1>
    </div>
    <div class="mx-auto max-w-7xl mt-4 mb-5">
      <div class="relative w-full md:w-52 flex items-start gap-3 bg-container p-3 text-sm mb-3">
        <img id="tps" class="absolute top-2 right-2 w-5 h-5" src={~p"/images/help-circle.svg"} />
        <img src={~p"/images/zap.svg"} class="my-auto" />
        <div class="flex">
          <div class="border-r border-r-gray-700 pr-4 mr-4">TPS</div>
          <div>
            <%= live_render(@socket, TPSComponent,
              id: "tps-number",
              session: %{"network" => Map.get(assigns, :network)}
            ) %>
          </div>
        </div>
      </div>
      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-5">
        <a href={~p"/#{@network}/blocks"} class="bg-container text-gray-100">
          <div class="relative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/box.svg"} class="my-auto w-6 h-auto" />
              <div>
                <div class="text-sm text-gray-400">Blocks Height</div>
                <div class="text-2xl mt-1"><%= assigns.block_height %></div>
              </div>
            </div>
            <div class="flex justify-between border-t border-t-gray-700 py-3 px-8">
              <div class="text-sm">View all blocks</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </div>
        </a>
        <a href={~p"/#{@network}/messages"} class="bg-container text-gray-100">
          <div class="reative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/message-square.svg"} class="my-auto w-6 h-auto" />
              <div>
                <div class="text-sm text-gray-400">Messages</div>
                <div class="text-2xl mt-1"><%= @entities_count.message_count %></div>
              </div>
            </div>
            <div class="flex justify-between border-t border-t-gray-700 py-3 px-8">
              <div class="text-sm">View all messages</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </div>
        </a>
        <a href={~p"/#{@network}/events"} class="bg-container text-gray-100">
          <div class="reative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/calendar.svg"} class="my-auto w-6 h-auto" />
              <div>
                <div class="text-sm text-gray-400">Events</div>
                <div class="text-2xl mt-1"><%= @entities_count.events_count %></div>
              </div>
            </div>
            <div class="flex justify-between border-t border-t-gray-700 py-3 px-8">
              <div class="text-sm">View all events</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </div>
        </a>
        <a href={~p"/#{@network}/transactions"} class="bg-container text-gray-100">
          <div class="reative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/check-square.svg"} class="my-auto w-6 h-auto" />
              <div>
                <div class="text-sm text-gray-400">Transactions</div>
                <div class="text-2xl mt-1"><%= @entities_count.transaction_count %></div>
              </div>
            </div>
            <div class="flex justify-between border-t border-t-gray-700 py-3 px-8">
              <div class="text-sm">View all transactions</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </div>
        </a>
      </div>
    </div>

    <div class="mx-auto max-w-7xl grid lg:grid-cols-2 lg:gap-5 xl:gap-16 mt-16">
      <div>
        <div class="table-header">
          <div class="table-title">Latest Blocks</div>
          <a
            href={Utils.network_path(@network, "blocks")}
            class="text-gray-300 hover:text-white transition-all duration-300"
          >
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
            <div id={"block-#{block.number}"} class="grid-6 custom-list-item">
              <div>
                <div class="list-h">Number</div>
                <%= live_redirect(to_string(block.number),
                  to: ~p"/#{assigns.network}/blocks/#{block.number}"
                ) %>
              </div>
              <div class="col-span-2">
                <div class="list-h">Block Hash</div>
                <div class="copy-container" id={"copy-block-#{block.number}"} phx-hook="Copy">
                  <div class="relative">
                    <%= live_redirect(Utils.shorten_block_hash(block.hash),
                      to: ~p"/#{assigns.network}/blocks/#{block.hash}",
                      class: "text-hover-blue",
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
        </div>
      </div>
      <div>
        <div class="table-header">
          <div class="table-title">Latest Transactions</div>
          <a
            href={Utils.network_path(@network, "transactions")}
            class="text-gray-300 hover:text-white transition-all duration-300"
          >
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
          <%= for {transaction, idx} <- Enum.take(Enum.with_index(@transactions), 15) do %>
            <div id={"transaction-#{idx}"} class="grid-7 custom-list-item">
              <div class="col-span-2">
                <div class="list-h">Transaction Hash</div>
                <div class="copy-container" id={"copy-transaction-#{idx}"} phx-hook="Copy">
                  <div class="relative">
                    <%= live_redirect(Utils.shorten_block_hash(transaction.hash),
                      to: ~p"/#{assigns.network}/transactions/#{transaction.hash}",
                      class: "text-hover-blue"
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
                  <span class={"#{if transaction.block_status == "ACCEPTED_ON_L2", do: "green-label"} #{if transaction.block_status == "ACCEPTED_ON_L1", do: "blue-label"} #{if transaction.block_status == "PENDING", do: "pink-label"}"}>
                    <%= transaction.block_status %>
                  </span>
                </div>
              </div>
              <div>
                <div class="list-h">Age</div>
                <%= Utils.get_block_age_from_timestamp(transaction.block_timestamp) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    blocks = StarknetExplorer.Data.many_blocks(socket.assigns.network)
    latest_block = blocks |> hd

    transactions =
      latest_block.transactions
      |> Enum.map(fn tx ->
        tx
        |> Map.put(:block_timestamp, latest_block.timestamp)
        |> Map.put(:block_status, latest_block.status)
      end)

    # get entities count and format for display
    entities_count =
      StarknetExplorer.Data.get_entity_count()
      |> Enum.map(fn {entity, count} ->
        {entity, StarknetExplorer.Utils.format_number_for_display(count)}
      end)
      |> Map.new()

    max_block_height =
      StarknetExplorer.Blockchain.ListenerWorker.get_height(
        StarknetExplorer.Utils.listener_atom(socket.assigns.network)
      )

    {:noreply,
     assign(socket,
       blocks: blocks,
       transactions: transactions,
       entities_count: entities_count,
       latest_block: latest_block,
       block_height: StarknetExplorer.Utils.format_number_for_display(max_block_height)
     )}
  end
end
