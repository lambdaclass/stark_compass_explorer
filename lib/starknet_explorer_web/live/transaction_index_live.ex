defmodule StarknetExplorerWeb.TransactionIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.CoreComponents
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Data
  alias StarknetExplorer.Transaction

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="table-header">
        <h2>Transactions</h2>
        <%= render_tx_filter(assigns) %>
        <CoreComponents.pagination_links
          id="transactions-top-pagination"
          page={@page}
          prev="dec_txs"
          next="inc_txs"
          active_pagination_id={@active_pagination_id}
        />
      </div>
      <div class="table-block">
        <div class="grid-7 table-th">
          <div class="col-span-2">Transaction Hash</div>
          <div class="col-span-2">Type</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <div id="transactions">
          <%= for {transaction, idx} <- Enum.with_index(@page.entries) do %>
            <div id={"transaction-#{idx}"} class="grid-7 custom-list-item">
              <div class="col-span-2">
                <div class="list-h">Transaction Hash</div>
                <div class="block-data">
                  <div class="hash flex">
                    <a
                      href={
                        Utils.network_path(
                          @network,
                          "transactions/#{transaction.hash}"
                        )
                      }
                      class="text-hover-link"
                    >
                      <%= Utils.shorten_block_hash(transaction.hash) %>
                    </a>
                    <CoreComponents.copy_button text={transaction.hash} />
                  </div>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Type</div>
                <div>
                  <span class={"type #{String.downcase(transaction.type)}"}>
                    <%= transaction.type %>
                  </span>
                </div>
              </div>
              <div class="col-span-2">
                <div class="list-h">Status</div>
                <div>
                  <span class={"info-label #{String.downcase(transaction.status)}"}>
                    <%= transaction.status %>
                  </span>
                </div>
              </div>
              <div>
                <div class="list-h">Age</div>
                <%= Utils.get_block_age_from_timestamp(transaction.timestamp) %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      <div class="mt-2">
        <CoreComponents.pagination_links
          id="transactions-bottom-pagination"
          page={@page}
          prev="dec_txs"
          next="inc_txs"
          active_pagination_id={@active_pagination_id}
        />
      </div>
    </div>
    """
  end

  def render_tx_filter(assigns) do
    ~H"""
    <div>
      <div>
        <div
          id="dropdown"
          class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
          phx-hook="Dropdown"
        >
          <span class="networkSelected capitalize"><%= assigns.tx_filter %></span>
          <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
            <img
              alt="Dropdown menu"
              class="transform rotate-90 w-5 h-5"
              src={~p"/images/dropdown.svg"}
            />
          </span>
        </div>
        <div>
          <div class="options hidden">
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "ALL", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="ALL"
            >
              All
            </div>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "INVOKE", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="INVOKE"
            >
              Invoke
            </div>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "DEPLOY_ACCOUNT", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="DEPLOY_ACCOUNT"
            >
              Deploy Account
            </div>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "DEPLOY", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="DEPLOY"
            >
              Deploy
            </div>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "DECLARE", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="DECLARE"
              ,
            >
              Declare
            </div>
            <div
              class={"option #{if Map.get(assigns, :tx_filter) == "L1_HANDLER", do: "lg:!border-b-se-blue text-white", else: "lg:border-b-transparent text-gray-400"}"}
              phx-click="select-filter"
              ,
              phx-value-filter="L1_HANDLER"
              ,
            >
              L1 Handler
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    page = Transaction.paginate_transactions_for_index(%{}, socket.assigns.network)

    {:ok,
     assign(socket,
       page: page,
       active_pagination_id: "",
       tx_filter: "ALL"
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       latest_block: Data.latest_block_with_transactions(socket.assigns.network)
     )}
  end

  @impl true
  def handle_event("select-filter", %{"filter" => filter}, socket) do
    pagination(socket, 1, filter)
  end

  @impl true
  def handle_event("inc_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1
    pagination(socket, new_page_number, Map.get(socket.assigns, :tx_filter, "ALL"))
  end

  def handle_event("dec_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1
    pagination(socket, new_page_number, Map.get(socket.assigns, :tx_filter, "ALL"))
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    new_page_number = String.to_integer(page_number)
    pagination(socket, new_page_number, Map.get(socket.assigns, :tx_filter, "ALL"))
  end

  def handle_event("toggle-page-edit", %{"target" => target}, socket) do
    socket = assign(socket, active_pagination_id: target)
    {:noreply, push_event(socket, "focus", %{id: target})}
  end

  def pagination(socket, new_page_number, filter \\ "ALL") do
    page =
      Transaction.paginate_transactions_for_index(
        %{page: new_page_number},
        socket.assigns.network,
        filter
      )

    {:noreply, assign(socket, page: page, tx_filter: filter)}
  end
end
