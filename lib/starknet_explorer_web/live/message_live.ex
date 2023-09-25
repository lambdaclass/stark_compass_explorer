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
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Message</h2>
      <div class="font-normal text-gray-400 mt-2 lg:mt-0">
        <%= @message.timestamp
        |> DateTime.from_unix()
        |> then(fn {:ok, time} -> time end)
        |> Calendar.strftime("%c") %> UTC
      </div>
    </div>
    <div class="custom-list">
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Hash</div>
        <div class="copy-container" id={"copy-block-hash-#{@message.message_hash}"} phx-hook="Copy">
          <div class="relative">
            <div class="hash">
              <%= @message.message_hash %>
              <div class="ml-2 relative shrink-0">
                <img
                  class="copy-btn copy-text w-5 h-5"
                  src={~p"/images/copy.svg"}
                  data-text={@message.message_hash}
                />
                <img
                  class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                  src={~p"/images/check-square.svg"}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Type</div>
        <div class={"col-span-3 type #{@message.type}"}>
          <%= Message.friendly_message_type(@message.type) %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Direction</div>
        <div class="col-span-3">
          <%= if Message.is_l2_to_l1(@message.type) do %>
            <div>
              <span class="info-label green-label">L2</span>
              → <span class="info-label blue-label">L1</span>
            </div>
          <% else %>
            <div>
              <span class="info-label blue-label">L1</span>
              → <span class="info-label green-label">L2</span>
            </div>
          <% end %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Transaction Hash</div>
        <div
          class="copy-container col-span-3 text-se-link"
          id={"copy-transaction-hash-#{@message.message_hash}"}
          phx-hook="Copy"
        >
          <div class="relative">
            <div class="hash">
              <a
                href={Utils.network_path(@network, "transactions/#{@message.transaction_hash}")}
                class="text-se-link"
              >
                <span><%= @message.transaction_hash %></span>
              </a>
              <div class="ml-2 relative shrink-0">
                <img
                  class="copy-btn copy-text w-5 h-5"
                  src={~p"/images/copy.svg"}
                  data-text={@message.message_hash}
                />
                <img
                  class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                  src={~p"/images/check-square.svg"}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Timestamp</div>
        <div><%= Utils.get_block_age_from_timestamp(@message.timestamp) %></div>
      </div>
      <%= if !Message.is_l2_to_l1(@message.type) do %>
        <div class="custom-list-item grid-4 w-full">
          <div class="block-label !mt-0">L2 Selector</div>
          <div
            class="copy-container"
            id={"copy-message-selector-#{@message.selector}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="hash">
                <%= @message.selector %>
                <div class="ml-2 relative shrink-0">
                  <img
                    class="copy-btn copy-text w-5 h-5"
                    src={~p"/images/copy.svg"}
                    data-text={@message.selector}
                  />
                  <img
                    class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                    src={~p"/images/check-square.svg"}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
        <%= if @message.nonce != nil do %>
          <div class="grid-4 custom-list-item">
            <div class="block-label !mt-0">Nonce</div>
            <div class="info-label pink-label">
              <%= @message.nonce %>
            </div>
          </div>
        <% end %>
      <% end %>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Details</div>
        <div class="inner-block custom-list">
          <div class="custom-list-item">
            <%= if Message.is_l2_to_l1(@message.type) do %>
              <div class="block-label">From L2 Contract Address</div>
            <% else %>
              <div class="block-label">From L1 Contract Address</div>
            <% end %>
            <div
              class="copy-container"
              id={"copy-from-address-#{@message.from_address}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="hash">
                  <%= @message.from_address %>
                  <div class="ml-2 relative shrink-0">
                    <img
                      class="copy-btn copy-text w-5 h-5"
                      src={~p"/images/copy.svg"}
                      data-text={@message.from_address}
                    />
                    <img
                      class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                      src={~p"/images/check-square.svg"}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="custom-list-item">
            <%= if Message.is_l2_to_l1(@message.type) do %>
              <div class="block-label">To L1 Contract Address</div>
            <% else %>
              <div class="block-label">To L2 Contract Address</div>
            <% end %>
            <div
              class="copy-container"
              id={"copy-from-address-#{@message.to_address}"}
              phx-hook="Copy"
            >
              <div class="relative">
                <div class="hash">
                  <%= @message.to_address %>
                  <div class="ml-2 relative shrink-0">
                    <img
                      class="copy-btn copy-text w-5 h-5"
                      src={~p"/images/copy.svg"}
                      data-text={@message.to_address}
                    />
                    <img
                      class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                      src={~p"/images/check-square.svg"}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="custom-list-item grid-4">
        <div class="block-label !mt-0">Payload</div>
        <div class="inner-block custom-list">
          <div class="w-full index-value-grid custom-list-item">
            <div class="list-h">Index</div>
            <div class="list-h">Value</div>
            <%= for {payload_item, id} <- Enum.with_index(@message.payload) do %>
              <div class="self-start">
                <%= id %>
              </div>
              <div class="hash">
                <div class="copy-container" id={"copy-payload-#{id}"} phx-hook="Copy">
                  <div class="relative">
                    <div class="hash">
                      <%= payload_item %>
                      <div class="ml-2 relative shrink-0">
                        <img
                          class="copy-btn copy-text w-5 h-5"
                          src={~p"/images/copy.svg"}
                          data-text={payload_item}
                        />
                        <img
                          class="copy-check absolute top-0 left-0 w-5 h-5 opacity-0 pointer-events-none"
                          src={~p"/images/check-square.svg"}
                        />
                      </div>
                    </div>
                  </div>
                </div>
                <%=  %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params = %{"identifier" => hash}, _session, socket) do
    message = Message.get_by_hash(hash, socket.assigns.network)
    IO.inspect(message)

    message =
      case Message.is_l2_to_l1(message) do
        false ->
          tx = StarknetExplorer.Transaction.get_by_hash(message.transaction_hash)

          decimal_nonce =
            case tx.nonce do
              nil -> nil
              nonce -> nonce |> String.replace("0x", "") |> String.to_integer(16)
            end

          message |> Map.put(:selector, tx.entry_point_selector) |> Map.put(:nonce, decimal_nonce)

        _ ->
          message
      end

    assigns = [
      message: message
    ]

    {:ok, assign(socket, assigns)}
  end
end
