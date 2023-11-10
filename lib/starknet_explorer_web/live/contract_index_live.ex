defmodule StarknetExplorerWeb.ContractIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.{CoreComponents, Utils}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Contracts</h2>
        <CoreComponents.pagination_links
          id="events-top-pagination"
          page={@page}
          prev="dec_events"
          next="inc_events"
          active_pagination_id={@active_pagination_id}
        />
      </div>
      <div class="table-block">
        <div class="grid-3 table-th">
          <div>Address</div>
          <div>Class Hash</div>
          <div>Deployed At</div>
        </div>
        <%= for contract <- @page.entries do %>
          <div class="grid-3 custom-list-item">
            <div class="list-h">Address</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "contracts/#{contract.address}")}
                  class="text-hover-link"
                >
                  <%= contract.address |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={contract.address} />
              </div>
            </div>
            <div class="list-h">Class Hash</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "classes/#{contract.class_hash}")}
                  class="text-hover-link"
                >
                  <%= contract.class_hash |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={contract.class_hash} />
              </div>
            </div>
            <div>
              <div class="list-h">Deployed At</div>
              <div>
                <%= Utils.get_block_age_from_timestamp(contract.timestamp) %>
                <CoreComponents.tooltip
                  id="contract-timestamp-tooltip"
                  text={"#{contract.timestamp
                        |> DateTime.from_unix()
                        |> then(fn {:ok, time} -> time end)
                        |> Calendar.strftime("%c")} UTC"}
                  class="translate-y-px"
                />
              </div>
            </div>
          </div>
        <% end %>
      </div>
      <div class="mt-2">
        <CoreComponents.pagination_links
          id="events-bottom-pagination"
          page={@page}
          prev="dec_events"
          next="inc_events"
          active_pagination_id={@active_pagination_id}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    page =
      StarknetExplorer.Contract.get_page(
        %{page: 1},
        socket.assigns.network
      )

    assigns = [page: page, active_pagination_id: ""]
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

  def handle_event("toggle-page-edit", %{"target" => target}, socket) do
    socket = assign(socket, active_pagination_id: target)
    {:noreply, push_event(socket, "focus", %{id: target})}
  end

  def pagination(socket, new_page_number) do
    page =
      StarknetExplorer.Contract.get_page(
        %{page: new_page_number},
        socket.assigns.network
      )

    assigns = [page: page]
    {:noreply, assign(socket, assigns)}
  end
end
