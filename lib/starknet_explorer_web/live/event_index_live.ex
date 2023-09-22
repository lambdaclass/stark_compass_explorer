defmodule StarknetExplorerWeb.EventIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{Data, BlockUtils, Rpc, Events}

  @page_size 30

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
        <%= for {idx, event = %{"block_number" => block_number, "from_address" => from_address, "transaction_hash" => tx_hash}} <- Enum.with_index(@page["events"], fn element, index -> {index, element} end) do %>
          <div class="custom-list-item grid-6">
            <div>
              <div class="list-h">Identifier</div>
              <% identifier =
                Integer.to_string(block_number) <> "_" <> Integer.to_string(idx + @page_number) %>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{identifier}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all text-hover-blue">
                    <a
                      href={Utils.network_path(@network, "/events/#{identifier}")}
                      class="text-hover-blue"
                    >
                      <span><%= identifier %></span>
                    </a>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={identifier}
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
            <div>
              <div class="list-h">Block Number</div>
              <div>
                <span class="blue-label">
                  <a
                    href={Utils.network_path(@network, "/blocks/#{event["block_hash"]}")}
                    class="text-hover-blue"
                  >
                    <span><%= to_string(block_number) %></span>
                  </a>
                </span>
              </div>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <div>
                <a
                  href={Utils.network_path(@network, "/transactions/#{tx_hash}")}
                  class="text-hover-blue"
                >
                  <span><%= tx_hash |> Utils.shorten_block_hash() %></span>
                </a>
              </div>
            </div>
            <div>
              <div class="list-h">Name</div>
              <div>
                <%= Events.get_event_name(event, @network) %>
              </div>
            </div>
            <div class="list-h">From Address</div>
            <div>
              <a
                href={Utils.network_path(@network, "/contracts/#{from_address}")}
                class="text-hover-blue"
              >
                <span><%= from_address |> Utils.shorten_block_hash() %></span>
              </a>
            </div>
            <div>
              <div class="list-h">Age</div>
              <div>
                <%= Utils.get_block_age(@block) %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    block_height = BlockUtils.block_height(socket.assigns.network) - 1
    {:ok, block} = Rpc.get_block_by_number(block_height, socket.assigns.network)

    {:ok, page} =
      Data.get_events(
        %{
          "chunk_size" => @page_size,
          "from_block" => %{"block_number" => block_height},
          "to_block" => %{"block_number" => block_height}
        },
        socket.assigns.network
      )

    assigns = [
      page: page,
      page_number: 0,
      block: block
    ]

    {:ok, assign(socket, assigns)}
  end
end
