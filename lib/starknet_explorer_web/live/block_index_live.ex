defmodule StarknetExplorerWeb.BlockIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Block

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Blocks</h2>
        <CoreComponents.pagination_links
          id="blocks-top-pagination"
          page={@page}
          prev="dec_events"
          next="inc_events"
        />
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Number</div>
          <div class="col-span-2">Block Hash</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <%= for block <- @page.entries do %>
          <div id={"block-#{block.number}"} class="grid-6 custom-list-item">
            <div>
              <div class="list-h">Number</div>
              <a href={Utils.network_path(@network, "blocks/#{block.number}")} class="type">
                <span><%= to_string(block.number) %></span>
              </a>
            </div>
            <div class="col-span-2">
              <div class="list-h">Block Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "blocks/#{block.hash}")}
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
      <div class="mt-2">
        <CoreComponents.pagination_links
          id="blocks-bottom-pagination"
          page={@page}
          prev="dec_events"
          next="inc_events"
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page: Block.paginate_blocks(%{}, socket.assigns.network)
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       page: Block.paginate_blocks(%{}, socket.assigns.network)
     )}
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
    page =
      Block.paginate_blocks(
        %{page: new_page_number},
        socket.assigns.network
      )

    socket = assign(socket, page: page)

    {:noreply, push_event(socket, "blur", %{})}
  end
end
