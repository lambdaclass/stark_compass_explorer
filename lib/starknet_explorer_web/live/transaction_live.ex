defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Transaction
  alias StarknetExplorerWeb.Utils

  defp transaction_header(assigns) do
    ~H"""
    <div class="flex justify-center items-center pt-14">
      <h1>Transaction detail</h1>
    </div>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="overview"
    >
      Overview
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="events"
    >
      Events
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="message_logs"
    >
      Message Logs
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="internal_calls"
    >
      Internal Calls
    </button>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    <%= render_info(assigns) %>
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
    <table>
      <thead>
        <tr>
          <th>Identifier</th>
          <th>Block Number</th>
          <th>Transaction Hash</th>
          <th>Name</th>
          <th>From Address</th>
          <th>Age</th>
        </tr>
      </thead>
      <tbody id="transaction-events-data">
        <%= for signature <- @transaction_receipt.events do %>
          <tr>
            <td>
              <%= "0x008e571d599345e12730f53df66cf74bea8ad238d68844b71ebadb567eae7a1d_4"
              |> Utils.shorten_block_hash() %>
            </td>
            <td><%= @transaction_receipt.block_number %></td>
            <td><%= @transaction.hash |> Utils.shorten_block_hash() %></td>
            <td>Transfer</td>
            <td><%= @transaction.sender_address |> Utils.shorten_block_hash() %></td>
            <td>Age: 1h</td>
          </tr>
        <% end %>
      </tbody>
    </table>
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
  def render_info(%{transaction_view: "overview", transaction: tx} = assigns) do
    ~H"""
    <hr /> Transaction Hash: <%= @transaction.hash %>
    <hr /> Status: <%= @transaction_receipt.status %>
    <hr /> Block Hash: <%= @transaction_receipt.block_hash %>
    <hr /> Block Number: <%= @transaction_receipt.block_number %>
    <hr /> Transaction Type: <%= @transaction.type %>
    <hr /> Sender Address: <%= @transaction.sender_address %>
    <hr /> Actual Fee: <%= @transaction.max_fee %>
    <hr /> Max Fee: <%= @transaction_receipt.actual_fee %>
    <hr /> Nonce: <%= @transaction.nonce %>
    <hr /> Input Data <hr />
    <table>
      <thead>
        <tr>
          call approve(spender, amount) -> <%= "0x0219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c"
          |> Utils.shorten_block_hash() %>
        </tr>
        <tr>
          <th>Input</th>
          <th>Type</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody id="transaction-input-data">
        <tr id="transaction-input-0">
          <td>spender</td>
          <td>felt</td>
          <td>
            <%= "0x11cd02208d6ed241d3fc0dba144f09b70be03003c32e56de2d19aea99b0ca76"
            |> Utils.shorten_block_hash() %>
          </td>
        </tr>
        <tr id="transaction-input-1">
          <td>token_id</td>
          <td>felt</td>
          <td>1580969</td>
        </tr>
      </tbody>
    </table>
    <table>
      <thead>
        <tr>
          call swap(pool_id, token_from_addr, amount_from, amount_to_min) -> 0x015543c3708653cda9d418b4ccd3be11368e40636c10c44b18cfe756b6d88b29
        </tr>
        <tr>
          <th>Input</th>
          <th>Type</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody id="transaction-input-data">
        <tr id="transaction-input-0">
          <td>pool_id</td>
          <td>felt</td>
          <td>"0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"</td>
        </tr>
        <tr id="transaction-input-1">
          <td>token_from_addr</td>
          <td>felt</td>
          <td>"0x42b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2"</td>
        </tr>
        <tr id="transaction-input-1">
          <td>amount_from</td>
          <td>Uint256</td>
          <td>"71587356859985694"</td>
        </tr>
        <tr id="transaction-input-1">
          <td>amount_to_min</td>
          <td>Uint256</td>
          <td>"80225122454772041"</td>
        </tr>
      </tbody>
    </table>
    <hr />
    <table>
      <thead>
        <tr>
          <th>Index</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody id="signatures">
        Signature
        <%= for {index, signature} <- Enum.with_index(@transaction.signature) do %>
          <tr id={"signature-#{index}"}>
            <td><%= index %></td>
            <td><%= signature %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    <hr />
    <div>
      Execution Resources
      STEPS 5083
      MEMORY 224
      PEDERSEN_BUILTIN 21
      RANGE_CHECK_BUILTIN 224
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

    transaction = %Transaction{} = Transaction.get_by_hash_with_receipt(transaction_hash)

    assigns = [
      transaction: transaction,
      transaction_receipt: transaction.receipt,
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
