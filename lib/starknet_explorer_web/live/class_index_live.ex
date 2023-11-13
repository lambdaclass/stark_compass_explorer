defmodule StarknetExplorerWeb.ClassIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorerWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Classes</h2>
        <CoreComponents.pagination_links
          id="events-top-pagination"
          page={@page}
          prev="dec_events"
          next="inc_events"
          active_pagination_id={@active_pagination_id}
        />
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Class Hash</div>
          <div class="col-span-2">Transaction Hash</div>
          <div class="col-span-2">Declared by</div>
          <div>Declared at</div>
        </div>
        <%= for class <- @page.entries do %>
          <div class="grid-6 custom-list-item">
            <div>
              <div class="list-h">Class Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "classes/#{class.hash}")}
                    class="text-hover-link"
                  >
                    <%= class.hash |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={class.hash} />
                </div>
              </div>
            </div>
            <div class="col-span-2">
              <div class="list-h">Transaction Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={
                      Utils.network_path(@network, "transactions/#{class.declared_at_transaction}")
                    }
                    class="text-hover-link"
                  >
                    <%= class.declared_at_transaction |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={class.declared_at_transaction} />
                </div>
              </div>
            </div>
            <div class="col-span-2">
              <div class="list-h">Declared by</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "contracts/#{class.declared_by_address}")}
                    class="text-hover-link"
                  >
                    <%= Utils.shorten_block_hash(class.declared_by_address) %>
                  </a>
                  <CoreComponents.copy_button text={class.declared_by_address} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">Declared at</div>
              <div class="block-data">
                <div class="flex items-center gap-2">
                  <%= Utils.get_block_age_from_timestamp(class.timestamp) %>
                  <CoreComponents.tooltip
                    id="class-timestamp-tooltip"
                    text={"#{class.timestamp
                        |> DateTime.from_unix()
                        |> then(fn {:ok, time} -> time end)
                        |> Calendar.strftime("%c")} UTC"}
                    class="translate-y-px"
                  />
                </div>
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
      StarknetExplorer.Class.get_page(
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
      StarknetExplorer.Class.get_page(
        %{page: new_page_number},
        socket.assigns.network
      )

    assigns = [page: page]
    {:noreply, assign(socket, assigns)}
  end
end
