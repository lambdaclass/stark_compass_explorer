defmodule StarknetExplorerWeb.ClassDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  defp class_detail_header(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="flex justify-center items-center pt-14">
      <h1 class="text-white text-4xl font-mono">Class Detail</h1>
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
      phx-value-view="deployed-contracts"
    >
      Deployed Contracts
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="proxied-contracts"
    >
      Proxied Contracts
    </button>
    <button
      class="font-bold py-2 px-4 rounded bg-blue-500 text-white"
      phx-click="select-view"
      ,
      phx-value-view="code"
    >
      Code
    </button>
    """
  end

  def mount(_params = %{"hash" => hash}, _session, socket) do
    # {:ok, block} =
    #   case num_or_hash(param) do
    #     :hash ->
    #       Rpc.get_block_by_hash(param)

    #     :num ->
    #       {num, ""} = Integer.parse(param)
    #       Rpc.get_block_by_number(num)
    #   end

    # assigns = [
    #   block: block,
    #   view: "overview"
    # ]

    assigns = [
      class: nil,
      view: "overview"
    ]

    # {:ok, assign(socket, assigns)}
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= class_detail_header(assigns) %>
    <%= render_info(assigns) %>
    """
  end

  def render_info(assigns = %{class: class, view: "deployed-contracts"}) do
    ~H"""
    <table>
      <tbody id="deployed-contracts">
        <h1>Deployed Contracts</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Contract Address</th>
                <th>Type</th>
                <th>Class Hash</th>
                <th>Deployed At</th>
              </tr>
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x02eb7823cce8b6e15c027b509a8d1a7e3d2afc4ec32e892902c67e4abd4beb81"
                    ) %>
                  </td>
                  <td>ERC20</td>
                  <td>
                    <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                    |> Utils.shorten_block_hash() %>
                  </td>
                  <td>22h</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{class: class, view: "proxied-contracts"}) do
    ~H"""
    <table>
      <tbody id="proxied-contracts">
        <h1>Proxied Contracts</h1>
        <%= for _ <- 0..10 do %>
          <table>
            <thead>
              <tr>
                <th>Contract Address</th>
                <th>Type</th>
                <th>Class Hash</th>
                <th>Deployed At</th>
              </tr>
              <tbody>
                <tr>
                  <td>
                    <%= Utils.shorten_block_hash(
                      "0x02eb7823cce8b6e15c027b509a8d1a7e3d2afc4ec32e892902c67e4abd4beb81"
                    ) %>
                  </td>
                  <td>ERC20</td>
                  <td>
                    <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
                    |> Utils.shorten_block_hash() %>
                  </td>
                  <td>22h</td>
                </tr>
              </tbody>
            </thead>
          </table>
        <% end %>
      </tbody>
    </table>
    """
  end

  def render_info(assigns = %{class: _block, view: "overview"}) do
    ~H"""
    <table>
      <thead>
        <ul>
          <li>Class Hash 0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2</li>
          <li>
            Declared By Contract Address 0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2
          </li>
          <li>
            Declared At Transaction Hash 0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2
          </li>
          <li>Declared At July 4, 2023 at 7:10:11 PM GMT-3</li>
          <li>Class Version Cairo 1.0</li>
        </ul>
      </thead>
    </table>
    """
  end

  def render_info(assigns = %{class: _block, view: "code"}) do
    ~H"""
    <table>
      <thead>
        <ul>
          TODO
        </ul>
      </thead>
    </table>
    """
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
