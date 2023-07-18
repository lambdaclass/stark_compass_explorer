defmodule StarknetExplorerWeb.ContractDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  defp contract_detail_header(assigns) do
    ~H"""
    <div class="flex flex-row justify-between lg:justify-start gap-5 items-baseline pb-5 lg:pb-0">
      <div class="flex flex-col lg:flex-row items-baseline gap-2">
        <h2>Contract</h2>
        <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
        |> Utils.shorten_block_hash() %>
      </div>
      <div class="">
        <span class="gray-label text-sm">Mocked</span>
      </div>
    </div>
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-5 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
      <span class="absolute inset-y-0 right-5 transform translate-1/2 flex items-center">
        <img class="transform rotate-90 w-5 h-5" src={~p"/images/dropdown.svg"} />
      </span>
    </div>
    <div class="options hidden">
      <div
        class={"option #{if assigns.view == "overview", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.view == "transactions", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
      <div
        class={"option #{if assigns.view == "events", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="events"
      >
        Events
      </div>
      <div
        class={"option #{if assigns.view == "account-calls", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="account-calls"
      >
        Account Calls
      </div>
      <div
        class={"option #{if assigns.view == "message-logs", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="message-logs"
      >
        Message Logs
      </div>
      <div
        class={"option #{if assigns.view == "portfolio", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="portfolio"
      >
        Portfolio
      </div>
      <div
        class={"option #{if assigns.view == "class-code-history", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="class-code-history"
      >
        Class Code/History
      </div>
      <div
        class={"option #{if assigns.view == "read-write-contract", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="read-write-contract"
      >
        Read/Write Contract
      </div>
      <div
        class={"option #{if assigns.view == "token-transfers", do: "lg:border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="token-transfers"
      >
        Token Transfers
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"address" => _}, _session, socket) do
    assigns = [
      contract: nil,
      view: "overview"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= contract_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "overview"}) do
    ~H"""
    <div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Contract Address</div>
        <div>
          <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Class Hash</div>
        <div>
          <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Eth Balance</div>
        <div>0.003035759798471112 ETH</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Type</div>
        <div>PROXY ACCOUNT</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Deployed By Contract Address</div>
        <div>
          <%= "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Deployed At Transaction Hash</div>
        <div>
          <%= "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Deployed At</div>
        <div>July 5, 2023 at 5:30:51 PM GMT-3</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Class Version</div>
        <div>Cairo 0</div>
      </div>
    </div>
    """
  end

  def render_info(assigns = %{contract: _, view: "transactions"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-7">
      <div>Transaction Hash</div>
      <div>Block Number</div>
      <div>Status</div>
      <div>Type</div>
      <div>Calls</div>
      <div>Address</div>
      <div>Age</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-7 custom-list-item">
        <div>
          <div class="list-h">Transaction Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
          ) %>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div>98133</div>
        </div>
        <div>
          <div class="list-h">Status</div>
          <div>ACCEPTED_ON_L2</div>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>DEPLOY_ACCOUNT</div>
        </div>
        <div>
          <div class="list-h">Calls</div>
          <div>constructor</div>
        </div>
        <div>
          <div class="list-h">Address</div>
          <div>
            <%= Utils.shorten_block_hash(
              "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
            ) %>
          </div>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div>25min</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "events"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-6">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>From Address</div>
      <div>Age</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-6 custom-list-item">
        <div>
          <div class="list-h">Identifier</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div>98133</div>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
          ) %>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>account_created</div>
        </div>
        <div>
          <div class="list-h">From Address</div>
          <%= Utils.shorten_block_hash(
            "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
          ) %>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div>28min</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "account-calls"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-6">
      <div>Identifier</div>
      <div>Block Number</div>
      <div>Transaction Hash</div>
      <div>Name</div>
      <div>Contract Address</div>
      <div>Age</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-6 custom-list-item">
        <div>
          <div class="list-h">Identifier</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Block Number</div>
          <div>98133</div>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
          ) %>
        </div>
        <div>
          <div class="list-h">Name</div>
          <div>account_created</div>
        </div>
        <div>
          <div class="list-h">Contract Address</div>
          <%= Utils.shorten_block_hash(
            "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
          ) %>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div>28min</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "message-logs"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-8">
      <div>Identifier</div>
      <div>Message Hash</div>
      <div>Direction</div>
      <div>Type</div>
      <div>From Address</div>
      <div>To Address</div>
      <div>Transaction Hash</div>
      <div>Age</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-8 custom-list-item">
        <div>
          <div class="list-h">Identifier</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Message Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Direction</div>
          <div>L2 -> L1</div>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>REGISTERED_ON_L1</div>
        </div>
        <div>
          <div class="list-h">From Address</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">To Address</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Transaction Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Age</div>
          <div>9min</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "portfolio"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-3">
      <div>Symbol</div>
      <div>Token</div>
      <div>Balance</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-3 custom-list-item">
        <div>
          <div class="list-h">Symbol</div>
          <div>ETH</div>
        </div>
        <div>
          <div class="list-h">Token</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Balance</div>
          <div>0.001133486641858774</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "class-code-history"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "read-write-contract"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "token-transfers"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-9">
      <div>Transaction Hash</div>
      <div>Call</div>
      <div>Events</div>
      <div>Account Calls</div>
      <div>Message Logs</div>
      <div>Portfolio</div>
      <div>Class/Code History</div>
      <div>Read/Write Contract</div>
      <div>Token Transfers</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-9 custom-list-item">
        <div>
          <div class="list-h">Transaction Hash</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Call</div>
          <div>transfer</div>
        </div>
        <div>
          <div class="list-h">Events</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Account Calls</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Message Logs</div>
          <div>0.001569</div>
        </div>
        <div>
          <div class="list-h">Portfolio</div>
          <%= Utils.shorten_block_hash(
            "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
          ) %>
        </div>
        <div>
          <div class="list-h">Class/Code History</div>
          <div>1h</div>
        </div>
        <div>
          <div class="list-h">Read/Write Contract</div>
          <div>1h</div>
        </div>
        <div>
          <div class="list-h">Token Transfers</div>
          <div>1h</div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
