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
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-5 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden"></div>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
        <div class="font-semibold">
          <h3>Message <%= @message.message_hash %></h3>
        </div>
        <div class="text-gray-400">
          <%= @message.timestamp
          |> DateTime.from_unix()
          |> then(fn {:ok, time} -> time end)
          |> Calendar.strftime("%c") %> UTC
        </div>
      </div>
      <div class="flex flex-col lg:flex-row gap-2 items-baseline pb-5"></div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Hash</div>
        <div
          class="copy-container col-span-3 text-hover-blue"
          id={"copy-block-hash-#{@message.message_hash}"}
          phx-hook="Copy"
        >
          <div class="relative">
            <div class="col-span-3">
              <%= @message.message_hash %>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={@message.message_hash}
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
        <div
          class="copy-container col-span-3 text-hover-blue"
          id={"copy-block-hash-#{@message.message_hash}"}
          phx-hook="Copy"
        >
          <div class="relative">
            <div class="col-span-3">
              <a
                href={Utils.network_path(@network, "transactions/#{@message.transaction_hash}")}
                class="text-hover-blue"
              >
                <span><%= @message.transaction_hash %></span>
              </a>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={@message.transaction_hash}
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
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Timestamp</div>
        <div class="col-span-3"><%= Utils.get_block_age_from_timestamp(@message.timestamp) %></div>
      </div>
      <%= if !Message.is_l2_to_l1(@message.type) do %>
        <div class="custom-list-item grid-4 w-full">
          <div class="custom-list-item grid-4 w-full !border-none">
            <div class="block-label !mt-0">L2 Selector</div>
          </div>
          <div>
            <%= @message.selector %>
          </div>
        </div>
        <%= if @message.nonce != nil do %>
          <div class="custom-list-item grid-4 w-full">
            <div class="custom-list-item grid-4 w-full !border-none">
              <div class="block-label !mt-0">Nonce</div>
            </div>
            <div>
              <span class="pink-label">
                <%= @message.nonce %>
              </span>
            </div>
          </div>
        <% end %>
      <% end %>
      <div class="custom-list-item">
        <div class="block-label !mt-0">Message Details</div>
        <div class="bg-black/10 p-5">
          <div class="custom-list-item grid-4 w-full !border-none">
            <%= if Message.is_l2_to_l1(@message.type) do %>
              <div class="block-label !mt-0">From L2 Contract Address</div>
            <% else %>
              <div class="block-label !mt-0">From L1 Contract Address</div>
            <% end %>

            <div
              class="copy-container col-span-3 text-hover-blue"
              id={"copy-block-hash-#{@message.to_address}"}
              phx-hook="Copy"
            >
              <%= @message.from_address %>
            </div>
          </div>
          <div class="custom-list-item grid-4 w-full">
            <div class="custom-list-item grid-4 w-full !border-none">
              <%= if Message.is_l2_to_l1(@message.type) do %>
                <div class="block-label !mt-0">To L1 Contract Address</div>
              <% else %>
                <div class="block-label !mt-0">To L2 Contract Address</div>
              <% end %>
            </div>
            <div
              class="copy-container col-span-3 text-hover-blue"
              id={"copy-block-hash-#{@message.to_address}"}
              phx-hook="Copy"
            >
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
