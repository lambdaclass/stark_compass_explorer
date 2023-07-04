defmodule StarknetExplorerWeb.TransactionIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="table-header">
        <h2>Transactions</h2>
      </div>
      <div class="table-block">
        <ul class="transactions-grid table-th">
          <li class="col-span-2" scope="col">Transaction Hash</li>
          <li class="col-span-2" scope="col">Type</li>
          <li class="col-span-2" scope="col">Status</li>
          <li scope="col">Age</li>
        </ul>
        <div id="transactions">
          <%= for block <- @latest_block do %>
            <%= for {transaction, idx} <- Enum.with_index(block["transactions"]) do %>
              <ul id={"transaction-#{idx}"} class="transactions-grid border-t border-gray-600">
                <li class="col-span-2" scope="row">
                  <%= live_redirect(Utils.shorten_block_hash(transaction["transaction_hash"]),
                    to: "/transactions/#{transaction["transaction_hash"]}",
                    class: "text-se-blue hover:text-se-hover-blue underline-none"
                  ) %>
                </li>
                <li class="col-span-2" scope="row">
                  <%= transaction["type"] %>
                </li>
                <li class="col-span-2" scope="row"><%= block["status"] %></li>
                <li scope="row"><%= Utils.get_block_age(block) %></li>
              </ul>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: []
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(),
       latest_block: Utils.get_latest_block_with_transactions()
     )}
  end
end
