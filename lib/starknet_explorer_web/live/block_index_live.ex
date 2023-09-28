defmodule StarknetExplorerWeb.BlockIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data
  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Blocks</h2>
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Number</div>
          <div class="col-span-2">Block Hash</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <%= for block <- @blocks do %>
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
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       blocks: Data.many_blocks(socket.assigns.network)
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Data.many_blocks(socket.assigns.network)
     )}
  end
end
