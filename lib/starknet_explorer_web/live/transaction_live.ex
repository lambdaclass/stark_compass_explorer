defmodule StarknetExplorerWeb.TransactionLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc

  def render(assigns) do
    ~H"""
    Transaction Details
    <ul>
      <li>Hash: <%= @transaction["transaction_hash"] %></li>
      <li>Block Number: <%= @transaction_receipt["block_number"] %></li>
      <li>Status: <%= @transaction_receipt["status"] %></li>
      <li>Type: <%= @transaction["type"] %></li>
      <li>Calls: <%= @transaction["transaction_hash"] %></li>
      <li>Address: <%= @transaction["sender_address"] %></li>
      <li>Age: <%= @transaction["transaction_hash"] %></li>
    </ul>
    """
  end

  def mount(
        _params,
        %{"transaction_hash" => transaction_hash},
        socket
      ) do
    {:ok, transaction} = Rpc.get_transaction(transaction_hash)
    |> IO.inspect(label: "Transaction")

    {:ok, transaction_receipt} = Rpc.get_transaction_receipt(transaction_hash)
    |> IO.inspect(label: "Transaction Receipt")

    assigns = [
      transaction: transaction,
      transaction_receipt: transaction_receipt
    ]

    socket = assign(socket, assigns)
    {:ok, socket}
  end
end
