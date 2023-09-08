defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data

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
        Message Logs <span class="gray-label text-sm">Mocked</span>
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
      <div>Transaction Hash</div>
      <div>Name</div>
      <%= if @transaction.sender_address do %>
        <div>From Address</div>
      <% end %>
      <div>Age</div>
    </div>
    <%= for %{keys: [identifier | _], from_address: _} <- @events do %>
      <div class={"custom-list-item #{if @transaction.sender_address, do: "grid-6", else: "grid-5"}"}>
        <div>
          <div class="list-h">Identifier</div>
          <div>
            <%= identifier |> Utils.shorten_block_hash() %>
          </div>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div><span class="blue-label"><%= @transaction_receipt.block_number %></span></div>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <div><%= @transaction.hash |> Utils.shorten_block_hash() %></div>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>
            <span class="lilac-label">Transfer</span>
            <span class="gray-label text-sm">Mocked</span>
          </div>
        </div>
        <%= if @transaction.sender_address do %>
          <div>
            <div class="list-h">From Address</div>
            <div><%= @transaction.sender_address |> Utils.shorten_block_hash() %></div>
          </div>
        <% end %>
        <div>
          <div class="list-h">Age</div>
          <div>1h</div>
        </div>
      </div>
    <% end %>
    """
  end

  # TODO:
  # Everything here is hardcoded.
  # I think this information comes from the block.
  def render_info(%{transaction_view: "message_logs"} = assigns) do
    ~H"""
    <div class="grid-8 table-th !pt-7 border-t border-gray-700">
      <div>Identifier</div>
      <div>Message Hash</div>
      <div>Direction</div>
      <div>Type</div>
      <div>From Address</div>
      <div>To Address</div>
      <div>Transaction Hash</div>
      <div>Age</div>
    </div>
    <div class="grid-8 custom-list-item">
      <div>
        <div class="list-h">Identifier</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div>
        <div class="list-h">Message Hash</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div>
        <div class="list-h">Direction</div>
        <div><span class="green-label">L2</span>><span class="blue-label">L1</span></div>
      </div>
      <div>
        <div class="list-h">Type</div>
        <div>Sent On L2</div>
      </div>
      <div>
        <div class="list-h">From Address</div>
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div>
        <div class="list-h">To Address</div>
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
        <div class="list-h">Age</div>
        <div>9min</div>
      </div>
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
      <div class="col-span-3"><%= @transaction_receipt.actual_fee %></div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Max Fee</div>
      <div class="col-span-3">
        <span class="bg-se-cash-green/10 text-se-cash-green rounded-full px-4 py-1">
          <%= @transaction.max_fee %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Nonce</div>
      <div class="col-span-3"><%= @transaction.nonce %></div>
    </div>
    <div class="custom-list-item">
      <div class="mb-5 text-gray-500 md:text-white !flex-row gap-2">
        <span>Input Data</span><span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="col-span-full">
        <div class="w-full bg-black/20 p-5 mt-5">
          call <span class="text-se-violet">approve</span>(<span class="text-blue-400">spender</span>, <span class="text-blue-400">amount</span>)
          <span class="text-blue-400">-></span> <%= Utils.shorten_block_hash(
            "0x0219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c"
          ) %>
        </div>
        <div class="w-full bg-black/10 p-5">
          <div class="grid-3 table-th">
            <div>Input</div>
            <div>Type</div>
            <div>Value</div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>spender</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>felt</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div class="break-all">
                <%= Utils.shorten_block_hash(
                  "0x11cd02208d6ed241d3fc0dba144f09b70be03003c32e56de2d19aea99b0ca76"
                ) %>
              </div>
            </div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>token_id</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>felt</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div>1580969</div>
            </div>
          </div>
        </div>
        <div class="w-full bg-black/20 p-5 mt-5">
          call <span class="text-se-violet">swap</span>(<span class="text-blue-400">pool_id</span>, <span class="text-blue-400">token_from_addr</span>, <span class="text-blue-400">amount_from</span>, <span class="text-blue-400">amount_to_min</span>)
          <span class="text-blue-400">-></span>
          <%= "0x015543c3708653cda9d418b4ccd3be11368e40636c10c44b18cfe756b6d88b29"
          |> Utils.shorten_block_hash() %>
        </div>
        <div class="w-full bg-black/10 p-5">
          <div class="grid-3 table-th">
            <div>Input</div>
            <div>Type</div>
            <div>Value</div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>pool_id</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>felt</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div class="break-all">
                <%= "0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"
                |> Utils.shorten_block_hash() %>
              </div>
            </div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>token_from_addr</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>felt</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div class="break-all">
                <%= "0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"
                |> Utils.shorten_block_hash() %>
              </div>
            </div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>amount_from</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>Uint256</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div><%= "71587356859985694" |> Utils.shorten_block_hash() %></div>
            </div>
          </div>
          <div class="grid-3 custom-list-item">
            <div>
              <div class="list-h">Input</div>
              <div>amount_to_min</div>
            </div>
            <div>
              <div class="list-h">Type</div>
              <div>Uint256</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div><%= "80225122454772041" |> Utils.shorten_block_hash() %></div>
            </div>
          </div>
        </div>
      </div>
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
      Data.transaction(transaction_hash, socket.assigns.network)

    assigns = [
      transaction: transaction,
      transaction_receipt: transaction.receipt,
      transaction_hash: transaction_hash,
      transaction_view: "overview",
      events: receipt.events
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
