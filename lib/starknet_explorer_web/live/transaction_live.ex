defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  defp transaction_header(assigns) do
    ~H"""
    Transaction <br />
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

  def render(%{transaction: nil, transaction_receipt: nil} = assigns) do
    ~H"""

    """
  end

  def render(%{transaction_view: "events"} = assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    <table>
      <thead>
        <tr>
          <th>Identifier(TODO)</th>
          <th>Block Number</th>
          <th>Transaction Hash</th>
          <th>Name(TODO)</th>
          <th>From Address</th>
          <th>Age(TODO)</th>
        </tr>
      </thead>
      <tbody id="transaction-events-data">
        <%= for signature <- @transaction_receipt["events"] do %>
          <tr>
            <td>TODO</td>
            <td><%= @transaction_receipt["block_number"] %></td>
            <td><%= @transaction["transaction_hash"] %></td>
            <td>TODO</td>
            <td><%= @transaction["sender_address"] %></td>
            <td>TODO</td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render(%{transaction_view: "message_logs"} = assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    """
  end

  def render(%{transaction_view: "internal_calls"} = assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    """
  end

  def render(%{transaction_view: "overview"} = assigns) do
    ~H"""
    <%= transaction_header(assigns) %>
    <hr /> Transaction Hash: <%= @transaction["transaction_hash"] %>
    <hr /> Status: <%= @transaction_receipt["status"] %>
    <hr /> Block Hash: <%= @transaction_receipt["block_hash"] %>
    <hr /> Block Number: <%= @transaction_receipt["block_number"] %>
    <hr /> TODO <hr /> Transaction Type: <%= @transaction["type"] %>
    <hr /> Sender Address: <%= @transaction["sender_address"] %>
    <hr /> Actual Fee: <%= @transaction["max_fee"] %>
    <hr /> Max Fee: <%= @transaction_receipt["actual_fee"] %>
    <hr /> Nonce: <%= @transaction["nonce"] %>
    <hr /> Input Data (TODO) <hr />
    <table>
      <thead>
        <tr>
          <th>Input</th>
          <th>Type</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody id="transaction-input-data">
        <tr id="transaction-input-0">
          <td>to</td>
          <td>felt</td>
          <td>0x11cd02208d6ed241d3fc0dba144f09b70be03003c32e56de2d19aea99b0ca76</td>
        </tr>
        <tr id="transaction-input-1">
          <td>token_id</td>
          <td>felt</td>
          <td>1580969</td>
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
        <%= for {index, signature} <- Enum.with_index(@transaction["signature"]) do %>
          <tr id={"signature-#{index}"}>
            <td><%= index %></td>
            <td><%= signature %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    <hr /> Execution Resources (TODO)
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
    {:ok, transaction} =
      Rpc.get_transaction(transaction_hash)

    {:ok, transaction_receipt} =
      Rpc.get_transaction_receipt(transaction_hash)

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
