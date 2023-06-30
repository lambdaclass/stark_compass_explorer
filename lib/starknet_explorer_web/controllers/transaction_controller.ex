defmodule StarknetExplorerWeb.TransactionController do
  use StarknetExplorerWeb, :controller

  def show(conn, %{"transaction_hash" => transaction_hash}) do
    # transaction = RPC.get_transaction(transaction_hash)
    live_render(conn, StarknetExplorerWeb.TransactionLive, session: %{
      "transaction_hash" => transaction_hash
    })
  end
end
