defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils

  defp transaction_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between">
      <h2>
        Transaction
        <span class="font-semibold">
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
          |> Utils.shorten_block_hash() %>
        </span>
      </h2>
    </div>
    <div class="flex gap-5 mt-8">
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.transaction_view == "overview", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.transaction_view == "events", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
      >
        Events
      </div>
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.transaction_view == "message_logs", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="message_logs"
      >
        Message Logs
      </div>
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.transaction_view == "internal_calls", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="internal_calls"
      >
        Internal Calls
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto bg-container p-4 md:p-8 rounded-md">
      <%= transaction_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(%{transaction: nil, transaction_receipt: nil} = assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    """
  end

  # TODO:
  # Do not hardcode the following:
  # Identifier
  # Name
  # Age
  def render_info(%{transaction_view: "events"} = assigns) do
    ~H"""
    <div class="grid grid-cols-6 gap-5">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for _signature <- @transaction_receipt["events"] do %>
      <div class="grid grid-cols-6 gap-5">
        <div>
          <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d_4"
          |> Utils.shorten_block_hash() %>
        </div>
        <div><%= @transaction_receipt["block_number"] %></div>
        <div><%= @transaction["transaction_hash"] |> Utils.shorten_block_hash() %></div>
        <div>Transfer</div>
        <div><%= @transaction["sender_address"] |> Utils.shorten_block_hash() %></div>
        <div>Age: 1h</div>
      </div>
    <% end %>
    """
  end

  # TODO:
  # Everything here is hardcoded.
  # I think this information comes from the block.
  def render_info(%{transaction_view: "message_logs"} = assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <th>Identifier</th>
          <th>Message Hash</th>
          <th>Direction</th>
          <th>Type</th>
          <th>From Address</th>
          <th>To Address</th>
          <th>Transaction Hash</th>
          <th>Age</th>
        </tr>
      </thead>
      <tbody id="message-logs-data">
        <tr>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>L2 -> L1</td>
          <td>Sent On L2</td>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>9min</td>
        </tr>
      </tbody>
    </table>
    """
  end

  def render_info(%{transaction_view: "internal_calls"} = assigns) do
    ~H"""
    <table>
      <thead>
        <tr>
          <th>Identifier</th>
          <th>Transaction Hash</th>
          <th>Type</th>
          <th>Name</th>
          <th>Contract Address</th>
        </tr>
      </thead>
      <tbody id="message-logs-data">
        <tr>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
          <td>Call</td>
          <td>__execute__</td>
          <td>
            <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d"
            |> Utils.shorten_block_hash() %>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  # TODO:
  # Do not hardcode the following:
  # Call data
  # Signatures
  # Execution resources
  def render_info(%{transaction_view: "overview"} = assigns) do
    ~H"""
    <div class="block-overview">
      <div class="block-label">Transaction Hash</div>
      <div class="col-span-3 break-all">
        <%= @transaction["transaction_hash"] %>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Transaction Type</div>
      <div class="col-span-3">
        <span class={"#{if @transaction["type"] == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
          <%= @transaction["type"] %>
        </span>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Status</div>
      <div class="col-span-3">
        <span class={"#{if @transaction_receipt["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if @transaction_receipt["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if @transaction_receipt["status"] == "PENDING", do: "pink-label"}"}>
          <%= @transaction_receipt["status"] %>
        </span>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Block Number</div>
      <div class="col-span-3">
        <span class="blue-label"><%= @transaction_receipt["block_number"] %></span>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Block Hash</div>
      <div class="col-span-3 text-hover-blue break-all">
        <%= @transaction_receipt["block_hash"] %>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Sender Address</div>
      <div class="col-span-3 break-all">
        <%= @transaction["sender_address"] %>
      </div>
    </div>
    <div class="block-overview">
      <div class="block-label">Actual Fee</div>
      <div class="col-span-3"><%= @transaction["max_fee"] %></div>
    </div>
    <div class="block-overview">
      <div class="block-label">Max Fee</div>
      <div class="col-span-3"><%= @transaction_receipt["actual_fee"] %></div>
    </div>
    <div class="block-overview">
      <div class="block-label">Nonce</div>
      <div class="col-span-3"><%= @transaction["nonce"] %></div>
    </div>
    <div class="block-overview">
      <div class="block-label">Input Data</div>
      <div class="col-span-full">
        <div class="bg-black/20 p-5 mt-5">
          call <span class="text-se-violet">approve</span>(<span class="text-blue-400">spender</span>, <span class="text-blue-400">amount</span>)
          <span class="text-blue-400">-></span> <%= Utils.shorten_block_hash(
            "0x0219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c"
          ) %>
        </div>
        <div class="bg-black/10 p-5">
          <div class="grid grid-cols-3 px-5 text-gray-400">
            <div>Input</div>
            <div>Type</div>
            <div>Value</div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>spender</div>
            <div>felt</div>
            <div class="break-all">
              <%= Utils.shorten_block_hash(
                "0x11cd02208d6ed241d3fc0dba144f09b70be03003c32e56de2d19aea99b0ca76"
              ) %>
            </div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>token_id</div>
            <div>felt</div>
            <div>1580969</div>
          </div>
        </div>
        <div class="bg-black/20 p-5 mt-5">
          call <span class="text-se-violet">swap</span>(<span class="text-blue-400">pool_id</span>, <span class="text-blue-400">token_from_addr</span>, <span class="text-blue-400">amount_from</span>, <span class="text-blue-400">amount_to_min</span>)
          <span class="text-blue-400">-></span>
          <%= "0x015543c3708653cda9d418b4ccd3be11368e40636c10c44b18cfe756b6d88b29"
          |> Utils.shorten_block_hash() %>
        </div>
        <div class="bg-black/10  p-5">
          <div class="grid grid-cols-3 px-5 text-gray-400">
            <div>Input</div>
            <div>Type</div>
            <div>Value</div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>pool_id</div>
            <div>felt</div>
            <div class="break-all">
              <%= "0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>token_from_addr</div>
            <div>felt</div>
            <div class="break-all">
              <%= "0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>amount_from</div>
            <div>Uint256</div>
            <div><%= "71587356859985694" |> Utils.shorten_block_hash() %></div>
          </div>
          <div class="grid grid-cols-3 px-5 border-t border-t-gray-700 mt-3 pt-2">
            <div>amount_to_min</div>
            <div>Uint256</div>
            <div><%= "80225122454772041" |> Utils.shorten_block_hash() %></div>
          </div>
        </div>
      </div>
    </div>
    <div class="block-overview">
      <div class="col-span-full">Signature</div>
      <div class="col-span-full bg-black/10 p-5">
        <div class="grid grid-cols-8 gap-5 px-5 text-gray-400">
          <div>Index</div>
          <div class="col-span-7">Value</div>
        </div>
        <%= for {index, signature} <- Enum.with_index(@transaction["signature"]) do %>
          <div class="grid grid-cols-8 gap-5 px-5 border-t border-t-gray-700 pt-4 mt-4">
            <div class="break-all"><%= signature %></div>
            <div class="break-all col-span-7"><%= index %></div>
          </div>
        <% end %>
      </div>
    </div>
    <div class="block-overview">
      <div class="col-span-full">Execution Resources</div>
      <div class="flex gap-10">
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

  def mount(%{"transaction_hash" => transaction_hash}, _session, socket) do
    Process.send(self(), :load_transaction, [])

    assigns = [
      transaction_hash: transaction_hash,
      transaction: nil,
      transaction_receipt: nil,
      transaction_view: "overview"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_info(
        :load_transaction,
        %{assigns: %{transaction_hash: transaction_hash}} = socket
      ) do
    {:ok, transaction} = Rpc.get_transaction(transaction_hash)

    {:ok, transaction_receipt} = Rpc.get_transaction_receipt(transaction_hash)

    assigns = [
      transaction: transaction,
      transaction_receipt: transaction_receipt,
      transaction_hash: socket.assigns.transaction_hash,
      transaction_view: socket.assigns.transaction_view
    ]

    socket = assign(socket, assigns)
    {:noreply, socket}
  end

  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :transaction_view, view)
    {:noreply, socket}
  end
end
