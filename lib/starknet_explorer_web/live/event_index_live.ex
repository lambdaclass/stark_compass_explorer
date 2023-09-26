defmodule StarknetExplorerWeb.EventIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{BlockUtils, Events}

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
        <%= for {event, _index} <- Enum.with_index(@page.entries) do %>
          <div class="custom-list-item grid-6">
            <div>
              <div class="list-h">Identifier</div>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-event-id-#{event.id}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all text-hover-blue">
                    <a
                      href={Utils.network_path(@network, "events/#{event.id}")}
                      class="text-hover-blue"
                    >
                      <span><%= event.id |> Utils.shorten_block_hash() %></span>
                    </a>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={event.id}
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
                    href={Utils.network_path(@network, "blocks/#{event.block_number}")}
                    class="text-hover-blue"
                  >
                    <span><%= to_string(event.block_number) %></span>
                  </a>
                </span>
              </div>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <div>
                <a
                  href={Utils.network_path(@network, "transactions/#{event.transaction_hash}")}
                  class="text-hover-blue"
                >
                  <span><%= event.transaction_hash |> Utils.shorten_block_hash() %></span>
                </a>
              </div>
            </div>
            <div>
              <div class="list-h">Name</div>
              <div>
                <%= if !String.starts_with?(event.name, "0x") do %>
                  <%= event.name %>
                <% else %>
                  <div
                    class="flex gap-2 items-center copy-container"
                    id={"copy-name-#{event.id}"}
                    phx-hook="Copy"
                  >
                    <div class="relative">
                      <div class="break-all">
                        <span><%= event.name |> Utils.shorten_block_hash() %></span>
                      </div>
                      <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                        <div class="relative">
                          <img
                            class="copy-btn copy-text w-4 h-4"
                            src={~p"/images/copy.svg"}
                            data-text={event.name}
                          />
                          <img
                            class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                            src={~p"/images/check-square.svg"}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
            <div class="list-h">From Address</div>
            <div><%= event.from_address |> Utils.shorten_block_hash() %></div>
            <div>
              <div class="list-h">Age</div>
              <div>
                <%= Utils.get_block_age_from_timestamp(event.age) %>
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
    {:ok, block_height} = BlockUtils.block_height(socket.assigns.network)

    page =
      Events.paginate_events(
        %{page: 1},
        block_height,
        socket.assigns.network
      )

    assigns = [
      page: page,
      page_number: 0
    ]

    {:ok, assign(socket, assigns)}
  end
end
