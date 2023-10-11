defmodule StarknetExplorerWeb.EventIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{BlockUtils, Events}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Events</h2>
        <CoreComponents.pagination_links id="events" page={@page} prev="dec_events" next="inc_events" />
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
              <div class="block-data">
                <div class="hash flex">
                  <a href={Utils.network_path(@network, "events/#{event.id}")} class="text-hover-link">
                    <%= event.id |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={event.id} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">Block Number</div>
              <div>
                <a href={Utils.network_path(@network, "blocks/#{event.block_number}")} class="type">
                  <span><%= to_string(event.block_number) %></span>
                </a>
              </div>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "transactions/#{event.transaction_hash}")}
                    class="text-hover-link"
                  >
                    <%= event.transaction_hash |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={event.transaction_hash} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">Name</div>
              <div>
                <%= if !String.starts_with?(event.name, "0x") do %>
                  <div class={"info-label #{String.downcase(event.name)}"}><%= event.name %></div>
                <% else %>
                  <div class="block-data">
                    <div class="hash flex">
                      <%= event.name |> Utils.shorten_block_hash() %>
                      <CoreComponents.copy_button text={event.name} />
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
            <div class="list-h">From Address</div>
            <div class="block-data">
              <div class="hash flex">
                <%= event.from_address |> Utils.shorten_block_hash() %>
                <CoreComponents.copy_button text={event.from_address} />
              </div>
            </div>
            <div>
              <div class="list-h">Age</div>
              <div>
                <%= Utils.get_block_age_from_timestamp(event.age) %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
      <div class="mt-2">
        <CoreComponents.pagination_links id="events" page={@page} prev="dec_events" next="inc_events" />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, block_height} = BlockUtils.block_height(socket.assigns.network)

    page =
      Events.paginate_events(
        %{},
        block_height,
        socket.assigns.network
      )

    assigns = [
      page: page
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("inc_events", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1
    pagination(socket, new_page_number)
  end

  def handle_event("dec_events", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1
    pagination(socket, new_page_number)
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    new_page_number = String.to_integer(page_number)
    pagination(socket, new_page_number)
  end

  def pagination(socket, new_page_number) do
    {:ok, block_height} = BlockUtils.block_height(socket.assigns.network)

    page =
      Events.paginate_events(
        %{page: new_page_number},
        block_height,
        socket.assigns.network
      )

    {:noreply, assign(socket, page: page)}
  end
end
