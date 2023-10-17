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
      <div class="table-header flex flex-col md:flex-row gap-5 !items-start">
        <h2>Transactions</h2>
        <div class="flex justify-between md:justify-end items-center">
          <div class="w-1/2 pr-6 max-w-[15rem] flex gap-3 items-center">
            <span class="hidden md:block text-gray-400">TYPE:</span>
            <%= render_tx_filter(assigns) %>
          </div>
          <CoreComponents.pagination_links
            id="transactions-top-pagination"
            page={@page}
            prev="dec_txs"
            next="inc_txs"
          />
        </div>
      </div>
      <div class="table-block">
        <div class="grid-7 table-th">
          <div class="col-span-2">Transaction Hash</div>
          <div class="col-span-2">Type</div>
          <div class="col-span-2">Status</div>
          <div>Age</div>
        </div>
        <div id="transactions">
          <%= if length(@page.entries) == 0 do %>
            <div class="py-3 text-base">
              No results found.
            </div>
          <% else %>
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
      <div class="relative z-20">
        <form id="test" phx-change="select-filter">
          <select value={@tx_filter} name="filter" id="filter" class="bg-container border border-gray-700 text-brand rounded-md text-sm py-1 w-full">
            <%= Phoenix.HTML.Form.options_for_select(filter_options(), @tx_filter) %>
          </select>
        </form>
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
    IO.inspect(filter)
    pagination(assign(socket, tx_filter: filter), 1, filter)
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

  def pagination(socket, new_page_number, filter \\ "ALL") do
    page =
      Transaction.paginate_transactions_for_index(
        %{page: new_page_number},
        socket.assigns.network,
        filter
      )

    IO.inspect(Map.get(socket.assigns, :tx_filter))


    socket = assign(socket, page: page, tx_filter: filter)
    {:noreply, push_event(socket, "blur", %{})}
  end

  def filter_options, do: ["ALL", "INVOKE", "DEPLOY_ACCOUNT", "DEPLOY", "DECLARE", "L1_HANDLER"]
end
