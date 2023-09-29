defmodule StarknetExplorerWeb.ClassIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Class

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="max-w-7xl mx-auto">
      <div class="table-header !justify-start gap-5">
        <h2>Classes</h2>
      </div>
      <div class="table-block">
        <div class="grid-3 table-th">
          <div>Class Hash</div>
          <div>Type</div>
          <div>Declared At</div>
        </div>
        <%= for {class, idx} <- Enum.with_index(Enum.take(@classes, 30))  do %>
          <div d={"class-#{idx}"} class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Class Hash</div>
              <div class="copy-container" id={"copy-class-#{idx}"} phx-hook="Copy">
                <div class="relative">
                  <a
                    href={
                      Utils.network_path(
                        @network,
                        "classes/#{class.class_hash}"
                      )
                    }
                    class="text-hover-blue"
                  >
                    <span><%= Utils.shorten_block_hash(class.class_hash) %></span>
                  </a>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={class.class_hash}
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
              <div class="list-h">Type</div>
              <span class="pink-label">
                <%= Utils.sanitize(class.type) %>
              </span>
            </div>
            <div>
              <div class="list-h">Declared At</div>
              <div>
                <%= Utils.format_timestamp(class.timestamp) %>
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
    classes = Class.latest_n_messages(socket.assigns.network, 20)
    {:ok, assign(socket, classes: classes)}
  end

  @impl true
  def handle_info(:load_messages, socket) do
    classes = Class.latest_n_messages(socket.assigns.network, 20)
    {:noreply, assign(socket, classes: classes)}
  end
end
