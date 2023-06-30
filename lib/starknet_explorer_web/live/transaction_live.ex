defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  def render(%{transaction: nil, transaction_receipt: nil} = assigns) do
    ~H"""
    Transaction
    """
  end

  def render(%{transaction_view: :events} = assigns) do
    ~H"""
    Transaction
    """
  end

  def render(%{transaction_view: :messag_logs} = assigns) do
    ~H"""
    Transaction
    """
  end

  def render(%{transaction_view: :internal_calls} = assigns) do
    ~H"""
    Transaction
    """
  end

  def render(%{transaction_view: :overview} = assigns) do
    ~H"""
    Transaction <hr /> Transaction Hash: <%= @transaction["transaction_hash"] %>
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
      transaction_view: :overview
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
      |> IO.inspect(label: "Transaction")

    {:ok, transaction_receipt} =
      Rpc.get_transaction_receipt(transaction_hash)
      |> IO.inspect(label: "Transaction Receipt")

    assigns = [
      transaction: transaction,
      transaction_receipt: transaction_receipt
    ]

    socket = assign(socket, assigns)
    {:noreply, socket}
  end
end
