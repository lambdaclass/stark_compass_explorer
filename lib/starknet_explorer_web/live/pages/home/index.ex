defmodule StarknetExplorerWeb.HomeLive.Index do
  alias StarknetExplorerWeb.Component.TransactionsPerSecond, as: TPSComponent
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.IndexCache
  use Phoenix.Component
  use StarknetExplorerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = load_blocks(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="flex flex-col gap-1 justify-center items-center my-16">
      <h1>Stark Compass</h1>
      <div class="uppercase rounded-lg px-2 py-1 text-center blue-label text-xl font-medium mt-2">
        The only open source explorer for Starknet
      </div>
    </div>
    <div class="mx-auto max-w-7xl mt-4 mb-5">
      <div class="flex justify-between">
        <div class="relative inline-flex items-start gap-3 bg-container p-3 pr-4 text-sm mb-6">
          <img src={~p"/images/zap.svg"} class="my-auto" />
          <div class="flex">
            <div class="flex items-center gap-2 border-r border-r-gray-700 pr-2 mr-2">
              TPS
              <CoreComponents.tooltip
                id="tps-tooltip"
                text="The average transactions per second calculated from the last block"
                class="translate-y-px"
              />
            </div>
            <div>
              <%= live_render(@socket, TPSComponent,
                id: "tps-number",
                session: %{"network" => Map.get(assigns, :network)}
              ) %>
            </div>
          </div>
        </div>
        <div>
          <a href="https://github.com/lambdaclass/stark_compass_explorer">
            <div class="inline-flex items-start gap-3 bg-container hover:bg-[#272737] transition-all duration-300 p-3 pr-4 text-sm mb-6">
              <img src={~p"/images/github.svg"} class="my-auto" />
            </div>
          </a>
          <a href="https://twitter.com/LambdaStarknet">
            <div class="inline-flex items-start gap-3 bg-container hover:bg-[#272737] transition-all duration-300 p-3 pr-4 text-sm mb-6">
              <img src={~p"/images/twitter.svg"} class="my-auto" />
            </div>
          </a>
          <a href="https://t.me/LambdaStarkNet">
            <div class="inline-flex items-start gap-3 bg-container hover:bg-[#272737] transition-all duration-300 p-3 pr-4 text-sm mb-6">
              <img src={~p"/images/telegram.svg"} class="my-auto" />
            </div>
          </a>
        </div>
      </div>
      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4">
        <a href={Utils.network_path(@network, "blocks")} class="bg-container text-gray-100">
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
        <a href={Utils.network_path(@network, "messages")} class="bg-container text-gray-100">
          <div class="reative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/message-square.svg"} class="my-auto w-6 h-auto" />
              <div>
                <div class="text-sm text-gray-400">Messages</div>
                <div class="text-2xl mt-1"><%= @entities_count.messages_count %></div>
              </div>
            </div>
            <div class="flex justify-between border-t border-t-gray-700 py-3 px-8">
              <div class="text-sm">View all messages</div>
              <img src={~p"/images/arrow-right.svg"} />
            </div>
          </div>
        </a>
        <a href={Utils.network_path(@network, "events")} class="bg-container text-gray-100">
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
        <a href={Utils.network_path(@network, "transactions")} class="bg-container text-gray-100">
          <div class="reative bg-container">
            <div class="flex items-start gap-6 my-4 mx-8">
              <img src={~p"/images/corner-up-right.svg"} class="my-auto w-6 h-auto" />
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
      <div class="text-gray-600 bg-gray-800/10 border-t border-t-gray-700 flex justify-center items-center py-4 px-4 text-sm mt-6">
        <div>
          *We are still syncing historical data so the above numbers might not reflect the current status
        </div>
      </div>
    </div>

    <div class="mx-auto max-w-7xl grid lg:grid-cols-2 gap-10 lg:gap-5 mt-16">
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
                <a href={Utils.network_path(assigns.network, "blocks/#{block.number}")} class="type">
                  <span><%= to_string(block.number) %></span>
                </a>
              </div>
              <div class="col-span-2">
                <div class="list-h">Block Hash</div>
                <div class="block-data">
                  <div class="hash flex">
                    <a
                      href={Utils.network_path(assigns.network, "blocks/#{block.hash}")}
                      class="text-hover-link"
                    >
                      <span><%= Utils.shorten_block_hash(block.hash) %></span>
                    </a>
                    <CoreComponents.copy_button text={block.hash} />
                  </div>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Status</div>
                <div>
                  <span class={"info-label #{String.downcase(block.status)}"}>
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
                <div class="block-data">
                  <div class="hash flex">
                    <a
                      href={Utils.network_path(assigns.network, "transactions/#{transaction.hash}")}
                      class="text-hover-link"
                    >
                      <span><%= Utils.shorten_block_hash(transaction.hash) %></span>
                    </a>
                    <CoreComponents.copy_button text={transaction.hash} />
                  </div>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Type</div>
                <div class={"type #{String.downcase(transaction.type)}"}>
                  <span>
                    <%= transaction.type %>
                  </span>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Status</div>
                <div>
                  <span class={"info-label #{String.downcase(transaction.block_status)}"}>
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
    <div>
    Related projects
    <div class="mx-auto max-w-7xl grid lg:grid-cols-3 gap-10 lg:gap-5 mt-16">
      <div class="table-block">
        <div>
          Read our blog
          <div>
            <a href="https://blog.lambdaclass.com">https://blog.lambdaclass.com</a>
          </div>
        </div>
      </div>
      <div class="table-block">
        <div>
          YAS
          <div>
            YAS is Yet Another Swap on Starknet but bringing the best prices and yield to Degens.
          </div>
          <div>
            <a>
              https://www.yetanotherswap.com
            </a>
          </div>
        </div>
      </div>
      <div class="table-block">
        <div>
          Follow LambdaStarknet on twitter
          <div>
            <a>
              https://twitter.com/LambdaStarknet
            </a>
          </div>
        </div>
      </div>
      </div>
    </div>
    """
  end

  def load_blocks(socket) do
    blocks =
      if length(IndexCache.latest_blocks(socket.assigns.network)) < 15 do
        StarknetExplorer.Data.many_blocks_with_txs(socket.assigns.network)
      else
        IndexCache.latest_blocks(socket.assigns.network)
      end

    case List.first(blocks) do
      nil ->
        assign(socket,
          blocks: [],
          transactions: [],
          entities_count: %{
            messages_count: 0,
            events_count: 0,
            transaction_count: 0
          },
          latest_block: 0,
          block_height: 0
        )

      latest_block ->
        transactions =
          latest_block.transactions
          |> Enum.map(fn tx ->
            tx
            |> Map.put(:block_timestamp, latest_block.timestamp)
            |> Map.put(:block_status, latest_block.status)
          end)

        # get entities count and format for display
        entities_count =
          StarknetExplorer.Data.get_entity_count(socket.assigns.network)
          |> Enum.map(fn {entity, count} ->
            {entity, StarknetExplorer.Utils.format_number_for_display(count)}
          end)
          |> Map.new()

        {:ok, block_height} = StarknetExplorer.Rpc.get_block_height(socket.assigns.network)
        block_height = StarknetExplorer.Utils.format_number_for_display(block_height)

        assign(socket,
          blocks: blocks,
          transactions: transactions,
          entities_count: entities_count,
          latest_block: latest_block,
          block_height: block_height
        )
    end
  end
end
