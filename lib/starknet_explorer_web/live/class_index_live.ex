defmodule StarknetExplorerWeb.ClassIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  # <%= for {class, idx} <- Enum.with_index(@classes) do %>
  # <ul id={"class-#{idx}"} class="transactions-grid border-t border-gray-600">
  #             <li class="col-span-2" scope="row">
  #               <%= live_redirect(Utils.shorten_block_hash(class.hash),
  #                 to: "/classes/#{class.hash}",
  #                 class: "text-se-blue hover:text-se-hover-blue underline-none"
  #               ) %>
  #             </li>
  #             <li class="col-span-2" scope="row">
  #               <%= transaction["type"] %>
  #             </li>
  #             <li class="col-span-2" scope="row"><%= block["status"] %></li>
  #             <li scope="row"><%= Utils.get_block_age(block) %></li>
  #           </ul>
  # <% end %>

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="table-header">
        <h2>Classes</h2>
      </div>
      <div class="table-block">
        <ul class="transactions-grid table-th">
          <li class="col-span-2" scope="col">Class Hash</li>
          <li class="col-span-2" scope="col">Type</li>
          <li class="col-span-2" scope="col">Declared At</li>
        </ul>
        <div id="classes">
          <%= for idx <- 0..30 do %>
            <ul id={"class-#{idx}"} class="transactions-grid border-t border-gray-600">
              <li class="col-span-2" scope="row">
                <%= live_redirect(
                  Utils.shorten_block_hash(
                    "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                  ),
                  to: "/classes/0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2",
                  class: "text-se-blue hover:text-se-hover-blue underline-none"
                ) %>
              </li>
              <li class="col-span-2" scope="row">ERC721</li>
              <li class="col-span-2" scope="row">17h</li>
            </ul>
          <% end %>
        </div>
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
