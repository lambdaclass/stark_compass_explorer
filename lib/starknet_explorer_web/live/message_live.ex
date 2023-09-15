defmodule StarknetExplorerWeb.MessageDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Hash</div>
        <div class="col-span-3">
          <%= @message.message_hash
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Type</div>
        <div class="col-span-3"><%= Message.friendly_message_type(@message.type) %></div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Direction</div>
        <div class="col-span-3">
          <%= if Message.is_l2_to_l1(@message.type) do %>
            <div><span class="green-label">L2</span>→<span class="blue-label">L1</span></div>
          <% else %>
            <div><span class="blue-label">L1</span>→<span class="green-label">L2</span></div>
          <% end %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Transaction Hash</div>
        <div class="col-span-3">
          <%= @message.transaction_hash %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Timestamp</div>
        <div class="col-span-3"><%= Utils.get_block_age_from_timestamp(@message.timestamp) %></div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0">Message Details</div>
        <div class="bg-black/10 p-5">
          <div class="custom-list-item grid-4 w-full !border-none">
            <div class="block-label !mt-0">From Contract Address</div>
            <div>
              <%= @message.from_address %>
            </div>
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@message.from_address}
              />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
          <div class="custom-list-item grid-4 w-full">
            <div class="block-label !mt-0">To Contract Address</div>
            <div>
              <%= @message.to_address %>
            </div>
          </div>
        </div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0">Payload</div>
        <div class="bg-black/10 p-5">
          <div class="w-full grid-8 table-th">
            <div>Index</div>
            <div class="col-span-7">Value</div>
          </div>
          <div class="w-full grid-8 custom-list-item">
            <div>
              <div class="list-h">Index</div>
              <%= for {_, id} <- Enum.with_index(@message.payload) do %>
                <div class="break-all"><%= id %></div>
              <% end %>
            </div>
            <div>
              <div class="list-h">Value</div>
              <%= for {payload_item, _} <- Enum.with_index(@message.payload) do %>
                <div class="col-span-7">
                  <%= payload_item %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params = %{"identifier" => hash}, _session, socket) do
    message = Message.get_by_hash(hash)

    assigns = [
      message: message
    ]

    {:ok, assign(socket, assigns)}
  end
end
