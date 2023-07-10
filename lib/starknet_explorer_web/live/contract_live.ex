defmodule StarknetExplorerWeb.ContractDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils

  defp contract_detail_header(assigns) do
    ~H"""
    <div class="flex justify-center items-center pt-14">
      <h1 class="text-white text-4xl font-mono">Contract Detail</h1>
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
      phx-value-view="transactions"
    >
      Transactions
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
      phx-value-view="account-calls"
    >
      Account Calls
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="message-logs"
    >
      Message Logs
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="portfolio"
    >
      Portfolio
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="class-code-history"
    >
      Class Code/History
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="read-write-contract"
    >
      Read/Write Contract
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="token-transfers"
    >
      Token Transfers
    </button>
    """
  end

  def mount(_params = %{"address" => address}, _session, socket) do
    assigns = [
      contract: nil,
      view: "overview"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= contract_detail_header(assigns) %>
    <%= render_info(assigns) %>
    """
  end

  def render_info(assigns = %{contract: contract, view: "overview"}) do
    ~H"""
    <table>
      <thead>
        <ul>
          <li>Contract Address 0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2</li>
          <li>
            Class Hash 0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2
          </li>
          <li>
            Eth Balance 0.003035759798471112 ETH
          </li>
          <li>Type PROXY ACCOUNT</li>
          <li>
            Deployed By Contract Address 0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a
          </li>
          <li>
            Deployed At Transaction Hash 0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3
          </li>
          <li>Deployed At July 5, 2023 at 5:30:51 PM GMT-3</li>
          <li>Class Version Cairo 0</li>
        </ul>
      </thead>
    </table>
    """
  end

  def render_info(assigns = %{contract: contract, view: "transactions"}) do
    ~H"""
    <table>
      <tbody id="transactions">
        <h1>Transactions</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Transaction Hash</th>
                <th>Block Number</th>
                <th>Status</th>
                <th>Type</th>
                <th>Calls</th>
                <th>Address</th>
                <th>Age</th>
              </tr>
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
                    ) %>
                  </td>
                  <td>98133</td>
                  <td>ACCEPTED_ON_L2</td>
                  <td>DEPLOY_ACCOUNT</td>
                  <td>constructor</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
                    ) %>
                  </td>
                  <td>25min</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "events"}) do
    ~H"""
    <table>
      <tbody id="events">
        <h1>Events</h1>
        <%= for _ <- 0..10 do %>
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
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>98133</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
                    ) %>
                  </td>
                  <td>account_created</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
                    ) %>
                  </td>
                  <td>28min</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "account-calls"}) do
    ~H"""
    <table>
      <tbody id="account-calls">
        <h1>Account Calls</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Identifier</th>
                <th>Block Number</th>
                <th>Transaction Hash</th>
                <th>Name</th>
                <th>Contract Address</th>
                <th>Age</th>
              </tr>
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>98133</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3"
                    ) %>
                  </td>
                  <td>account_created</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x0358941c0a4b15738d1f5a6419f4e13d5bca0fdfe36b5548816e9d003989258a"
                    ) %>
                  </td>
                  <td>28min</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "message-logs"}) do
    ~H"""
    <table>
      <tbody id="message-logs">
        <h1>Message Logs</h1>
        <%= for _ <- 0..10 do %>
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
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>L2 -> L1</td>
                  <td>REGISTERED_ON_L1</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>
                    <td>
                      <%= Utils.shorten_block_hash(
                        "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                      ) %>
                    </td>
                  </td>
                  <td>9min</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "portfolio"}) do
    ~H"""
    <table>
      <tbody id="portfolio">
        <h1>Portfolio</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Token</th>
                <th>Balance</th>
              </tr>
              <tbody>
                <tr>
                  <td>ETH</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>0.001133486641858774</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "class-code-history"}) do
    ~H"""
    <table>
      <tbody>
        <thead>
          <h1>TODO</h1>
        </thead>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "read-write-contract"}) do
    ~H"""
    <table>
      <tbody>
        <thead>
          <h1>TODO</h1>
        </thead>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{contract: _contract, view: "token-transfers"}) do
    ~H"""
    <table>
      <tbody id="token-transfers">
        <h1>Token Transfers</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Transaction Hash</th>
                <th>Call</th>
                <th>Events</th>
                <th>Account Calls</th>
                <th>Message Logs</th>
                <th>Portfolio</th>
                <th>Class/Code History</th>
                <th>Read/Write Contract</th>
                <th>Token Transfers</th>
              </tr>
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>transfer</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>0.001569</td>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x065150851e490476ca3cc69dbd70911a03b305951335b3aeb77d2eb0ce757df3_0"
                    ) %>
                  </td>
                  <td>1h</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
