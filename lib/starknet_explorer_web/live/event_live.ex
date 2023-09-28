defmodule StarknetExplorerWeb.EventDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.{Events, Block}
  alias StarknetExplorerWeb.Utils
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="flex flex-col lg:flex-row gap-2 items-baseline pb-5">
        <h2>Event</h2>
        <div class="font-semibold">
          <%= @event.id %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Event ID</div>
        <div>
          <%= @event.id %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Hash</div>
        <div>
          <a
            href={
              Utils.network_path(
                @network,
                "blocks/#{@block.hash}"
              )
            }
            class="text-hover-blue"
          >
            <span><%= @block.hash %></span>
          </a>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Number</div>
        <a
          href={
            Utils.network_path(
              @network,
              "blocks/#{@event.block_number}"
            )
          }
          class="text-hover-blue"
        >
          <div><%= @event.block_number %></div>
        </a>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Transaction Hash</div>
        <div>
          <a
            href={
              Utils.network_path(
                @network,
                "blocks/#{@event.transaction_hash}"
              )
            }
            class="text-hover-blue"
          >
            <%= @event.transaction_hash %>
          </a>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Contract Address</div>
        <div>
          <%= @event.from_address %>
        </div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0 lg:pb-5">Event Data</div>
        <div class="bg-black/10 p-5">
          <div class="grid-3 w-full table-th">
            <div>Input</div>
            <div>Value</div>
          </div>
          <%= for {payload, index} <- Enum.with_index(@event.data) do %>
            <div class="grid-3 w-full custom-list-item">
              <div>
                <div class="list-h">Index</div>
                <div><%= index %></div>
              </div>
              <div>
                <div class="list-h">Value</div>
                <div><%= payload %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"identifier" => identifier}, _session, socket) do
    event = Events.get_by_id(identifier, socket.assigns.network)

    assigns = [
      event: event,
      block: Block.get_by_num(event.block_number, socket.assigns.network)
    ]

    {:ok, assign(socket, assigns)}
  end
end
