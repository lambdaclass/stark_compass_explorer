defmodule StarknetExplorerWeb.MessageIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto">
      <div class="table-header !justify-start gap-5">
        <h2>Messages</h2>
      </div>
      <div class="table-block">
        <div class="grid-6 table-th">
          <div>Message Hash</div>
          <div>Direction</div>
          <div>Type</div>
          <div>From Address</div>
          <div>To Address</div>
          <div>Transaction Hash</div>
        </div>
        <%= for message <- @messages do %>
          <div class="grid-6 custom-list-item">
            <div>
              <div class="list-h">Message Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "messages/#{message.message_hash}")}
                    class="text-hover-link"
                  >
                    <%= message.message_hash |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={message.message_hash} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">Direction</div>
              <%= if Message.is_l2_to_l1(message.type) do %>
                <div>
                  <span class="info-label green-label">L2</span>→<span class="info-label blue-label">L1</span>
                </div>
              <% else %>
                <div>
                  <span class="info-label blue-label">L1</span>→<span class="info-label green-label">L2</span>
                </div>
              <% end %>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div class={"type #{String.downcase(String.replace(Message.friendly_message_type(message.type), " ", "-"))}"}>
                <%= Message.friendly_message_type(message.type) %>
              </div>
            </div>
            <div>
              <div class="list-h">From Address</div>
              <div class="block-data">
                <div class="hash flex">
                  <%= Utils.shorten_block_hash(message.from_address) %>
                  <CoreComponents.copy_button text={message.from_address} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">To Address</div>
              <div class="block-data">
                <div class="hash flex">
                  <%= Utils.shorten_block_hash(message.to_address) %>
                  <CoreComponents.copy_button text={message.to_address} />
                </div>
              </div>
            </div>
            <div>
              <div class="list-h">Transaction Hash</div>
              <div class="block-data">
                <div class="hash flex">
                  <a
                    href={Utils.network_path(@network, "transactions/#{message.transaction_hash}")}
                    class="text-hover-link"
                  >
                    <%= message.transaction_hash |> Utils.shorten_block_hash() %>
                  </a>
                  <CoreComponents.copy_button text={message.transaction_hash} />
                </div>
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
    Process.send(self(), :load_messages, [])
    messages = Message.latest_n_messages(socket.assigns.network, 20)
    {:ok, assign(socket, messages: messages)}
  end

  @impl true
  def handle_info(:load_messages, socket) do
    # TODO: Fetch this from the db
    messages = Message.latest_n_messages(socket.assigns.network, 20)
    {:noreply, assign(socket, messages: messages)}
  end
end
