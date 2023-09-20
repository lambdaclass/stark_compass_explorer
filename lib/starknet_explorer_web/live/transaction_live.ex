defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.{Data, Message, Rpc, BlockUtils}

  defp transaction_header(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row gap-2 items-baseline mb-5 lg:mb-0">
      <h2>Transaction</h2>
      <div
        class="copy-container break-all pr-10 lg:pr-0"
        id={"tsx-header-#{@transaction.hash}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <div class="font-semibold">
            <%= @transaction.hash %>
          </div>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@transaction.hash}
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
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-5 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.transaction_view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.transaction_view == "overview", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.transaction_view == "events", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
      >
        Events
      </div>
      <div
        class={"option #{if assigns.transaction_view == "message_logs", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="message_logs"
      >
        Message Logs
      </div>
      <div
        class={"option #{if assigns.transaction_view == "internal_calls", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="internal_calls"
      >
        Internal Calls <span class="gray-label text-sm">Mocked</span>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= transaction_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  # TODO:
  # find a way to pass ID of copy container so that it isn't the same although you reuse the elements
  def render_info(%{transaction: nil, transaction_receipt: nil} = assigns) do
    ~H"""

    """
  end

  def render_info(%{transaction_view: "events"} = assigns) do
    ~H"""
    <div class={"table-th !pt-7 border-t border-gray-700 #{if @transaction.sender_address, do: "grid-6", else: "grid-5"}"}>
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for event <- @transaction_receipt.events do %>
      <div class={"custom-list-item #{if @transaction.sender_address, do: "grid-6", else: "grid-5"}"}>
        <div>
          <div class="list-h">Identifier</div>
          <div>
            <%= # TODO, this wont work yet. Fix when using SQL.
            @transaction_receipt.block_number %>
          </div>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div><span class="blue-label"><%= @transaction_receipt.block_number %></span></div>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>
            <%= Data.get_event_name(event, @network) %>
          </div>
        </div>
        <div>
          <div class="list-h">From Address</div>
          <div><%= event.from_address |> Utils.shorten_block_hash() %></div>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div><%= Utils.get_block_age_from_timestamp(@block_timestamp) %></div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(%{transaction_view: "message_logs"} = assigns) do
    ~H"""
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
                  <%= live_redirect(message.message_hash |> Utils.shorten_block_hash(),
                    to: ~p"/#{@network}/messages/#{message.message_hash}"
                  ) %>
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
                  <%= Utils.shorten_block_hash(message.from_address) %>
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
                  <%= Utils.shorten_block_hash(message.to_address) %>
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
                  <%= live_redirect(message.transaction_hash |> Utils.shorten_block_hash(),
                    to: ~p"/#{@network}/transactions/#{message.transaction_hash}"
                  ) %>
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
    """
  end

  def render_info(%{transaction_view: "internal_calls"} = assigns) do
    ~H"""
    <div class="grid-5 table-th !pt-7 border-t border-gray-700">
      <div>Identifier</div>
      <div>Transaction Hash</div>
      <div>Type</div>
      <div>Name</div>
      <div>Contract Address</div>
    </div>
    <div class="grid-5 custom-list-item">
      <div>
        <div class="list-h">Identifier</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div>
        <div class="list-h">Transaction Hash</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div>
        <div class="list-h">Type</div>
        <div><span class="lilac-label">Call</span></div>
      </div>
      <div>
        <div class="list-h">Name</div>
        <div><span class="green-label">__execute__</span></div>
      </div>
      <div>
        <div class="list-h">Contract Address</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
    </div>
    """
  end

  # TODO:
  # Do not hardcode the following:
  # Call data
  # Execution resources
  def render_info(%{transaction_view: "overview"} = assigns) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label">Transaction Hash</div>
      <div class="col-span-3 break-all">
        <div class="copy-container" id={"tsx-overview-hash-#{@transaction.hash}"} phx-hook="Copy">
          <div class="relative">
            <%= @transaction.hash |> Utils.shorten_block_hash() %>
            <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
              <div class="relative">
                <img
                  class="copy-btn copy-text w-4 h-4"
                  src={~p"/images/copy.svg"}
                  data-text={@transaction.hash}
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
      <div class="block-label">Transaction Type</div>
      <div class="col-span-3">
        <span class={"#{if @transaction.type == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
          <%= @transaction.type %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Status</div>
      <div class="col-span-3">
        <span class={"#{if @transaction_receipt.finality_status == "ACCEPTED_ON_L2", do: "green-label"} #{if @transaction_receipt.finality_status == "ACCEPTED_ON_L1", do: "blue-label"} #{if @transaction_receipt.finality_status == "PENDING", do: "pink-label"}"}>
          <%= @transaction_receipt.finality_status %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Number</div>
      <div class="col-span-3">
        <span class="blue-label"><%= @transaction_receipt.block_number %></span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Hash</div>
      <div class="col-span-3 text-hover-blue break-all">
        <div
          class="copy-container"
          id={"tsx-overview-block-#{@transaction_receipt.block_hash}"}
          phx-hook="Copy"
        >
          <div class="relative">
            <%= @transaction_receipt.block_hash |> Utils.shorten_block_hash() %>
            <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
              <div class="relative">
                <img
                  class="copy-btn copy-text w-4 h-4"
                  src={~p"/images/copy.svg"}
                  data-text={@transaction_receipt.block_hash}
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
    <%= if @transaction.sender_address do %>
      <div class="grid-4 custom-list-item">
        <div class="block-label">Sender Address</div>
        <div class="col-span-3 break-all">
          <div
            class="copy-container"
            id={"tsx-overview-addres-#{@transaction.sender_address}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <%= @transaction.sender_address |> Utils.shorten_block_hash() %>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img
                    class="copy-btn copy-text w-4 h-4"
                    src={~p"/images/copy.svg"}
                    data-text={@transaction.sender_address}
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
    <div class="grid-4 custom-list-item">
      <div class="block-label">Actual Fee</div>
      <div class="col-span-3">
        <span class="blue-label rounded-full px-4 py-1">
          <%= @transaction_receipt.actual_fee %> ETH
        </span>
      </div>
    </div>
    <%= if @transaction.sender_address do %>
      <div class="grid-4 custom-list-item">
        <div class="block-label">Max Fee</div>
        <div class="col-span-3">
          <span class="text-se-cash-green green-label rounded-full px-4 py-1">
            <%= @transaction.max_fee %> ETH
          </span>
        </div>
      </div>
    <% end %>

    <div class="grid-4 custom-list-item">
      <div class="block-label">Nonce</div>
      <div class="col-span-3">
        <%= @transaction.nonce |> String.replace("0x", "") |> String.to_integer(16) %>
      </div>
    </div>
    <div class="custom-list-item">
      <div class="mb-5 text-gray-500 md:text-white !flex-row gap-2">
        <span>Input Data</span>
      </div>
      <%= unless is_nil(@transaction.input_data) do %>
        <div class="col-span-full">
          <%= for input <- @transaction.input_data do %>
            <%= unless is_nil(input.call) do %>
              <div class="w-full bg-black/20 p-5 mt-5" phx-no-format>
                call <span class="text-se-violet"><%= input.call.name %></span>(<.intersperse
                  :let={arg}
                  enum={input.call.args}
                ><:separator>, </:separator>
                  <span class="text-blue-400"><%= arg.name %></span></.intersperse>)
                <span class="text-blue-400">-></span> <%= Utils.shorten_block_hash(input.selector) %>
              </div>
              <div class="w-full bg-black/10 p-5">
                <div class="grid-3 table-th">
                  <div>Input</div>
                  <div>Type</div>
                  <div>Value</div>
                </div>
                <%= for arg <- input.call.args do %>
                  <div class="grid-3 custom-list-item">
                    <div>
                      <div class="list-h">Input</div>
                      <div>
                        <%= arg.name %>
                      </div>
                    </div>
                    <div>
                      <div class="list-h">Type</div>
                      <div>
                        <%= arg.type %>
                      </div>
                    </div>
                    <div>
                      <div class="list-h">Value</div>
                      <div class="break-all">
                        <%= Utils.format_arg_value(arg) %>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="w-full bg-black/20 p-5 mt-5">
                Not Supported <span class="text-se-violet">...</span>(...)
                <span class="text-blue-400">-></span> <%= Utils.shorten_block_hash(input.selector) %>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    <div class="custom-list-item">
      <div class="mb-5 text-gray-500 md:text-white !flex-row gap-5">
        <span>Signature</span>
      </div>
      <div class="bg-black/10 p-5">
        <div class="w-full grid-8 table-th">
          <div>Index</div>
          <div class="col-span-7">Value</div>
        </div>
        <%= unless is_nil(@transaction.signature) do %>
          <%= for {signature, index} <- Enum.with_index(@transaction.signature) do %>
            <div class="w-full grid-8 custom-list-item">
              <div>
                <div class="list-h">Index</div>
                <div class="break-all"><%= index %></div>
              </div>
              <div>
                <div class="list-h">Value</div>
                <div class="break-all col-span-7"><%= signature |> Utils.shorten_block_hash() %></div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    <div class="pt-3 mb-3 border-t border-t-gray-700">
      <div class="mb-5 text-gray-500 md:text-white !flex-row gap-5">
        <span>Execution Resources</span><span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="flex flex-col lg:flex-row items-center gap-5 px-5 md:p-0">
        <div class="flex flex-col justify-center items-center gap-2">
          <span class="blue-label">STEPS</span> 5083
        </div>
        <div class="flex flex-col justify-center items-center gap-2">
          <span class="green-label">MEMORY</span> 224
        </div>
        <div class="flex flex-col justify-center items-center gap-2">
          <span class="pink-label">PEDERSEN_BUILTIN</span> 21
        </div>
        <div class="flex flex-col justify-center items-center gap-2">
          <span class="violet-label">RANGE_CHECK_BUILTIN</span> 224
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"transaction_hash" => transaction_hash}, _session, socket) do
    {:ok, transaction = %{receipt: receipt}} =
      Data.full_transaction(transaction_hash, socket.assigns.network)

    {:ok, %{"timestamp" => block_timestamp}} =
      Rpc.get_block_by_hash(receipt.block_hash, socket.assigns.network)

    # a tx should not have both L1->L2 and L2->L1 messages AFAIK, but just in case merge both scenarios
    messages_sent =
      (Message.from_transaction_receipt(receipt) ++ [Message.from_transaction(transaction)])
      |> Enum.reject(&is_nil/1)

    # change fee formatting
    actual_fee = Utils.hex_wei_to_eth(transaction.receipt.actual_fee)

    transaction =
      case transaction.type do
        "L1_HANDLER" ->
          max_fee = Utils.hex_wei_to_eth(transaction.max_fee)
          transaction |> Map.put(:max_fee, max_fee)

        _ ->
          transaction
      end

    receipt = transaction.receipt |> Map.put(:actual_fee, actual_fee)

    assigns = [
      transaction: transaction,
      transaction_receipt: receipt,
      transaction_hash: transaction_hash,
      transaction_view: "overview",
      events: receipt.events,
      messages: messages_sent,
      block_timestamp: block_timestamp
    ]

    socket = assign(socket, assigns)
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :transaction_view, view)
    {:noreply, socket}
  end
end
