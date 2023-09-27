defmodule StarknetExplorerWeb.ClassIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  # <%= for {class, idx} <- Enum.with_index(@classes) do %>
  # <ul id={"class-#{idx}"} class="transactions-grid border-t border-gray-600">
  #             <li class="col-span-2">
  #               <%= live_redirect(Utils.shorten_block_hash(class.hash),
  #                 to: "/classes/#{class.hash}",
  #                 class: "text-hover-blue"
  #               ) %>
  #             </li>
  #             <li class="col-span-2">
  #               <%= transaction["type"] %>
  #             </li>
  #             <li class="col-span-2"><%= block["status"] %></li>
  #             <li><%= Utils.get_block_age(block) %></li>
  #           </ul>
  # <% end %>

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header !justify-start gap-5">
        <h2>Classes</h2>
        <span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="table-block">
        <div class="grid-3 table-th">
          <div>Class Hash</div>
          <div>Type</div>
          <div>Declared At</div>
        </div>
        <%= for idx <- 0..30 do %>
          <div id={"class-#{idx}"} class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Class Hash</div>
              <%= Utils.shorten_block_hash(
                "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
              ) %>
            </div>
            <div>
              <div class="list-h">Type</div>
              <span class="violet-label">ERC721</span>
            </div>
            <div>
              <div class="list-h">Declared At</div>
              <div>17h</div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_classes, [])

    {:ok, assign(socket, classes: [])}
  end

  @impl true
  def handle_info(:load_classes, socket) do
    # TODO: Fetch this from the db
    {:noreply, assign(socket, classes: [])}
    # {:noreply, assign(socket, classes: Utils.list_classes())}
  end
end
