defmodule StarknetExplorerWeb.BlockIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data
  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto lg:mt-20">
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
              <a href={Utils.network_path(@network, "blocks/#{block.number}")} class="text-hover-blue">
                <span><%= to_string(block.number) %></span>
              </a>
            </div>
            <div class="col-span-2">
              <div class="list-h">Block Hash</div>
              <div class="copy-container" id={"copy-bk-#{block.number}"} phx-hook="Copy">
                <div class="relative">
                  <a
                    href={Utils.network_path(@network, "blocks/#{block.hash}")}
                    class="text-hover-blue"
                  >
                    <span><%= Utils.shorten_block_hash(block.hash) %></span>
                  </a>
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
