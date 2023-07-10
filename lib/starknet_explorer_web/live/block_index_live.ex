defmodule StarknetExplorerWeb.BlockIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Blocks</h2>
      </div>
      <div class="table-block">
        <div class="blocks-grid table-th">
          <div scope="col">Number</div>
          <div class="col-span-2" scope="col">Block Hash</div>
          <div class="col-span-2" scope="col">Status</div>
          <div scope="col">Age</div>
        </div>
        <div id="blocks">
          <%= for block <- @blocks do %>
            <div
              id={"block-#{block["block_number"]}"}
              class="blocks-grid border-t first-of-type:border-t-0 md:first-of-type:border-t border-gray-600 "
            >
              <div scope="row">
                <div class="list-h">Number</div>
                <%= live_redirect(to_string(block["block_number"]),
                  to: "/block/#{block["block_number"]}",
                  class: "blue-label"
                ) %>
              </div>
              <div class="col-span-2" scope="row">
                <div class="list-h">Block Hash</div>
                <div
                  class="copy-container flex gap-4 items-center"
                  id={"copy-bk-#{block["block_number"]}"}
                  phx-hook="Copy"
                >
                  <div class="relative">
                    <%= live_redirect(Utils.shorten_block_hash(block["block_hash"]),
                      to: "/block/#{block["block_hash"]}",
                      class: "text-hover-blue",
                      title: block["block_hash"]
                    ) %>
                    <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                      <div class="relative">
                        <img
                          class="copy-btn copy-text w-4 h-4"
                          src={~p"/images/copy.svg"}
                          data-text={block["block_hash"]}
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
              <div class="col-span-2" scope="row">
                <div class="list-h">Status</div>
                <div>
                  <span class={"#{if block["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if block["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if block["status"] == "PENDING", do: "pink-label"}"}>
                    <%= block["status"] %>
                  </span>
                </div>
              </div>
              <div scope="row">
                <div class="list-h">Age</div>
                <%= Utils.get_block_age(block) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: []
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(),
       latest_block: Utils.get_latest_block_with_transactions()
     )}
  end
end
