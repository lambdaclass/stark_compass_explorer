defmodule StarknetExplorerWeb.ContractDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Token
  alias StarknetExplorerWeb.{CoreComponents, Utils}

  @starkgate_eth_token System.get_env("ETH_BALANCE_CONTRACT") ||
                         "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
  @balanceOf_selector "0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e"

  defp contract_detail_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Contract</h2>
      <%= if !is_nil(@contract) do %>
        <div class="font-normal text-gray-400 mt-2 lg:mt-0">
          <%= @contract.timestamp
          |> DateTime.from_unix()
          |> then(fn {:ok, time} -> time end)
          |> Calendar.strftime("%c") %> UTC
        </div>
      <% end %>
    </div>
    """
  end

  defp tab_name("overview"), do: "Overview"
  defp tab_name("events"), do: "Events"
  defp tab_name("transactions"), do: "Transactions"
  defp tab_name("account-calls"), do: "Account Calls"
  defp tab_name("portfolio"), do: "Portfolio"
  defp tab_name("class-code-history"), do: "Class Code History"
  defp tab_name("read-write"), do: "Read/Write"
  defp tab_name("token-transfers"), do: "Token Transfers"
  defp tab_name(name), do: name

  defp contract_dropdown(assigns) do
    ~H"""
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= tab_name(assigns.view) %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img alt="Dropdown menu" class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.view == "overview", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.view == "transactions", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
      <div
        class={"option #{if assigns.view == "events", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
      >
        Events
      </div>
      <div
        class={"option #{if assigns.view == "account-calls", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"} !hidden"}
        phx-click="select-view"
        ,
        phx-value-view="account-calls"
      >
        Account Calls (WIP)
      </div>
      <div
        class={"option #{if assigns.view == "portfolio", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="portfolio"
      >
        Portfolio
      </div>
      <div
        class={"option #{if assigns.view == "class-code-history", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"} !hidden"}
        phx-click="select-view"
        ,
        phx-value-view="class-code-history"
      >
        Code History (WIP)
      </div>
      <div
        class={"option #{if assigns.view == "read-write", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"} !hidden"}
        phx-click="select-view"
        ,
        phx-value-view="read-write"
      >
        Read/Write (WIP)
      </div>
      <div
        class={"option #{if assigns.view == "token-transfers", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"} !hidden"}
        phx-click="select-view"
        ,
        phx-value-view="token-transfers"
      >
        Token Transfers (WIP)
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"address" => address}, _session, socket) do
    assigns =
      case StarknetExplorer.Contract.get_by_address(address, socket.assigns.network) do
        nil ->
          [
            view: "contract_not_found",
            contract: nil
          ]

        contract ->
          class = StarknetExplorer.Class.get_by_hash(contract.class_hash, socket.assigns.network)

          # Since the Eth balance is stored in the Starkgate: ETH Token contract, we need to request
          # the new balance from the Starknet node.
          {:ok, [balance_in_wei, _]} =
            StarknetExplorer.Rpc.call(
              "latest",
              @starkgate_eth_token,
              @balanceOf_selector,
              socket.assigns.network,
              [contract.address]
            )

          [
            contract: contract,
            view: "overview",
            class: class,
            balance: balance_in_wei
          ]
      end

    Process.send_after(self(), :fetch_portfolio, 100)

    {:ok,
     put_flash(
       assign(socket, assigns),
       :info,
       "We are working adding features to this page. Some info may be missing. Sorry for the inconvenience."
     )}
  end

  @impl true
  def render(%{contract: nil} = assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= contract_detail_header(assigns) %>
      <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">
        The contract was not found.
        We are still syncing the blockchain, please try again later.
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= contract_detail_header(assigns) %>
      <%= contract_dropdown(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(%{view: "overview"} = assigns) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label">Address</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <a
            href={Utils.network_path(@network, "contracts/#{@contract.address}")}
            class="text-hover-link"
          >
            <%= @contract.address %>
          </a>
          <CoreComponents.copy_button text={@contract.address} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Class Hash</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <a
            href={Utils.network_path(@network, "classes/#{@contract.class_hash}")}
            class="text-hover-link"
          >
            <%= @contract.class_hash %>
          </a>
          <CoreComponents.copy_button text={@contract.class_hash} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Eth Balance</div>
      <div class="col-span-3">
        <%= if is_nil(@balance) do %>
          <span class="info-label cash-label">WORK IN PROGRESS</span>
        <% else %>
          <span class="info-label cash-label">
            <%= Utils.hex_wei_to_eth(@balance) %> ETH
          </span>
        <% end %>
      </div>
    </div>

    <div class="grid-4 custom-list-item">
      <div class="block-label">Type</div>
      <div class="col-span-3">
        <CoreComponents.render_class_types class={@class} />
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Deployed by Address</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <%= if is_nil(@contract.deployed_by_address) do %>
            <span class="info-label">-</span>
          <% else %>
            <a
              href={Utils.network_path(@network, "contracts/#{@contract.deployed_by_address}")}
              class="text-hover-link"
            >
              <%= @contract.deployed_by_address %>
            </a>
            <CoreComponents.copy_button text={@contract.deployed_by_address} />
          <% end %>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Deployed at Transaction</div>
      <div class="block-data col-span-3">
        <div class="hash flex">
          <%= if is_nil(@contract.deployed_at_transaction) do %>
            <span class="info-label">-</span>
          <% else %>
            <a
              href={Utils.network_path(@network, "transactions/#{@contract.deployed_at_transaction}")}
              class="text-hover-link"
            >
              <%= # @contract.deployed_at_transaction %>
            </a>
            <CoreComponents.copy_button text={@contract.deployed_at_transaction} />
          <% end %>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">Class Version</div>
      <div class="col-span-3">
        <span class="type">
          <%= if is_nil(@class) do %>
            -
          <% else %>
            <%= Utils.format_version(@class.version) %>
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  def render_info(assigns = %{view: "transactions"}) do
    ~H"""
    <div class="grid-3 table-th !pt-7">
      <div>Hash</div>
      <div>Type</div>
      <div>Version</div>
    </div>
    <%= if @page.total_entries == 0 do %>
      <div class="grid-3 custom-list-item">
        <div class="text-gray-500 text-xl pt-5">
          No transactions found
        </div>
      </div>
    <% else %>
      <%= for %{hash: hash, type: type, version: version} <- @page.entries do %>
        <div class="grid-3 custom-list-item">
          <div>
            <div class="list-h">Hash</div>
            <div class="block-data">
              <div class="hash flex">
                <a href={Utils.network_path(@network, "transactions/#{hash}")} class="text-hover-link">
                  <span><%= Utils.shorten_block_hash(hash) %></span>
                </a>
                <CoreComponents.copy_button text={hash} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Type</div>
            <div>
              <span class={"type #{String.downcase(type)}"}>
                <%= type %>
              </span>
            </div>
          </div>
          <div>
            <div class="list-h">Version</div>
            <div><%= Utils.format_version(version) %></div>
          </div>
        </div>
      <% end %>
    <% end %>
    <div class="mt-2">
      <CoreComponents.pagination_links
        id="txs"
        page={@page}
        prev="dec_txs"
        next="inc_txs"
        active_pagination_id={@active_pagination_id}
      />
    </div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "events"}) do
    ~H"""
    <div class="table-th !pt-7 grid-3">
      <div>Identifier</div>
      <div>Transaction Hash</div>
      <div>Name</div>
    </div>
    <%= if @page.total_entries == 0 do %>
      <div class="grid-3 custom-list-item">
        <div class="text-gray-500 text-xl pt-5">
          No events found
        </div>
      </div>
    <% else %>
      <%= for event <- @page.entries do %>
        <div class="custom-list-item grid-3">
          <div>
            <div class="list-h">Identifier</div>
            <div class="block-data">
              <div class="hash flex">
                <a href={Utils.network_path(@network, "events/#{event.id}")} class="text-hover-link">
                  <%= event.id |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={event.id} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Transaction Hash</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "transactions/#{event.transaction_hash}")}
                  class="text-hover-link"
                >
                  <%= event.transaction_hash |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={event.transaction_hash} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Name</div>
            <div>
              <%= if !String.starts_with?(event.name, "0x") do %>
                <div class={"info-label #{String.downcase(event.name)}"}><%= event.name %></div>
              <% else %>
                <div class="block-data">
                  <div class="hash flex">
                    <%= event.name |> Utils.shorten_block_hash() %>
                    <CoreComponents.copy_button text={event.name} />
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    <% end %>
    <CoreComponents.pagination_links
      id="events"
      page={@page}
      prev="dec_events"
      next="inc_events"
      active_pagination_id={@active_pagination_id}
    />
    """
  end

  def render_info(assigns = %{contract: _contract, view: "account-calls"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "portfolio"}) do
    ~H"""
    <div class="table-block">
      <div class="grid-4 table-th">
        <div>Symbol</div>
        <div>Name</div>
        <div>Address</div>
        <div>Balance</div>
      </div>
      <%= for {token_info, token_balance} <- @tokens do %>
        <div class="grid-4 custom-list-item">
          <div class="list-h">Symbol</div>
          <div><%= token_info.symbol %></div>
          <div class="list-h">Name</div>
          <div class="type"><%= token_info.name %></div>
          <div class="list-h">Address</div>
          <div class="block-data">
            <div class="hash flex">
              <a
                href={Utils.network_path(@network, "contracts/#{token_info.address}")}
                class="text-hover-link"
              >
                <%= token_info.address |> Utils.shorten_block_hash() %>
              </a>
              <CoreComponents.copy_button text={token_info.address} />
            </div>
          </div>
          <div class="list-h">Balance</div>
          <div>
            <span class="info-label cash-label">
              <%= Utils.hex_wei_to_eth(token_balance) %> <%= token_info.symbol %>
            </span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "class-code-history"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "read-write"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "token-transfers"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  @impl true
  def handle_info(:fetch_portfolio, socket) do
    tokens = Token.contract_portfolio(socket.assigns.contract.address, socket.assigns.network)

    assigns = [
      tokens: tokens
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("dec_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number - 1

    page =
      StarknetExplorer.Transaction.get_page_by_sender_address(
        %{page: new_page_number},
        socket.assigns.contract.address,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "transactions"
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("inc_txs", _value, socket) do
    new_page_number = socket.assigns.page.page_number + 1

    page =
      StarknetExplorer.Transaction.get_page_by_sender_address(
        %{page: new_page_number},
        socket.assigns.contract.address,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "transactions"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "transactions"},
        socket
      ) do
    page =
      StarknetExplorer.Transaction.get_page_by_sender_address(
        %{page: 0},
        socket.assigns.contract.address,
        socket.assigns.network
      )

    assigns = [
      view: "transactions",
      page: page,
      active_pagination_id: "txs"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "events"},
        socket
      ) do
    page =
      StarknetExplorer.Events.get_page_by_address(
        %{page: 0},
        socket.assigns.contract.address,
        socket.assigns.network
      )

    assigns = [
      view: "events",
      page: page,
      active_pagination_id: "events"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event(
        "select-view",
        %{"view" => "portfolio"},
        %{assigns: %{tokens: _tokens}} = socket
      ) do
    assigns = [
      view: "portfolio"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => "portfolio"}, socket) do
    tokens = Token.contract_portfolio(socket.assigns.contract.address, socket.assigns.network)

    assigns = [
      view: "portfolio",
      tokens: tokens
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change-page",
        %{"page-number-input" => page_number},
        socket
      ) do
    new_page_number = String.to_integer(page_number)

    case socket.assigns.view do
      "transactions" ->
        page =
          StarknetExplorer.Transaction.get_page_by_sender_address(
            %{page: new_page_number},
            socket.assigns.contract.address,
            socket.assigns.network
          )

        assigns = [
          page: page,
          active_pagination_id: "txs"
        ]

        {:noreply, assign(socket, assigns)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle-page-edit", %{"target" => target}, socket) do
    socket = assign(socket, active_pagination_id: target)
    {:noreply, push_event(socket, "focus", %{id: target})}
  end
end
