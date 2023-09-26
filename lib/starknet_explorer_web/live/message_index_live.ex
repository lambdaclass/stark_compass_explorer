defmodule StarknetExplorerWeb.MessageIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message

  @impl true
  def render(assigns) do
    ~H"""
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
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{message.message_hash}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all text-hover-blue">
                    <a
                      href={Utils.network_path(@network, "messages/#{message.message_hash}")}
                      class="text-hover-blue"
                    >
                      <span><%= message.message_hash |> Utils.shorten_block_hash() %></span>
                    </a>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={message.message_hash}
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
              <div class="list-h">Direction</div>
              <%= if Message.is_l2_to_l1(message.type) do %>
                <div><span class="green-label">L2</span>→<span class="blue-label">L1</span></div>
              <% else %>
                <div><span class="blue-label">L1</span>→<span class="green-label">L2</span></div>
              <% end %>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>
                <%= Message.friendly_message_type(message.type) %>
              </div>
            </div>
            <div>
              <div class="list-h">From Address</div>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{message.from_address}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all">
                    <%= if Message.is_l2_to_l1(message.type) do %>
                      <%= Utils.shorten_block_hash(message.from_address) %>
                    <% else %>
                      <%= Utils.shorten_block_hash(message.from_address) %>
                    <% end %>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={message.from_address}
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
              <div class="list-h">To Address</div>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{message.to_address}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all">
                    <%= if Message.is_l2_to_l1(message.type) do %>
                      <%= Utils.shorten_block_hash(message.to_address) %>
                    <% else %>
                      <%= Utils.shorten_block_hash(message.to_address) %>
                    <% end %>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={message.to_address}
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
              <div class="list-h">Transaction Hash</div>
              <div
                class="flex gap-2 items-center copy-container"
                id={"copy-transaction-hash-#{message.transaction_hash}"}
                phx-hook="Copy"
              >
                <div class="relative">
                  <div class="break-all text-hover-blue">
                    <a
                      href={Utils.network_path(@network, "transactions/#{message.transaction_hash}")}
                      class="text-hover-blue"
                    >
                      <span><%= message.transaction_hash |> Utils.shorten_block_hash() %></span>
                    </a>
                  </div>
                  <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                    <div class="relative">
                      <img
                        class="copy-btn copy-text w-4 h-4"
                        src={~p"/images/copy.svg"}
                        data-text={message.transaction_hash}
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
