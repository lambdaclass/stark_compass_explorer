defmodule StarknetExplorerWeb.ClassDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  # defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  # defp num_or_hash(_num), do: :num

  defp class_detail_header(assigns) do
    ~H"""
    <div class="flex flex-row justify-between lg:justify-start gap-5 items-baseline pb-5 lg:pb-0">
      <div class="flex flex-col lg:flex-row gap-2 items-baseline">
        <h2>Class</h2>
        <div class="font-semibold">
          <%= Utils.shorten_block_hash(
            "0x02eb7823cce8b6e15c027b509a8d1a7e3d2afc4ec32e892902c67e4abd4beb81"
          ) %>
        </div>
      </div>
      <span class="gray-label text-sm">Mocked</span>
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
        class={"option #{if assigns.view == "overview", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"option #{if assigns.view == "deployed-contracts", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="deployed-contracts"
      >
        Deployed Contracts
      </div>
      <div
        class={"option #{if assigns.view == "proxied-contracts", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="proxied-contracts"
      >
        Proxied Contracts
      </div>
      <div
        class={"option #{if assigns.view == "code", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="code"
      >
        Code
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"hash" => _hash}, _session, socket) do
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
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= class_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{class: _, view: "deployed-contracts"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-4">
      <div>Contract Address</div>
      <div>Type</div>
      <div>Class Hash</div>
      <div>Deployed At</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-4 custom-list-item">
        <div>
          <div class="list-h">Contract Address</div>
          <%= Utils.shorten_block_hash(
            "0x02eb7823cce8b6e15c027b509a8d1a7e3d2afc4ec32e892902c67e4abd4beb81"
          ) %>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>ERC20</div>
        </div>
        <div>
          <div class="list-h">Class Hash</div>
          <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
          |> Utils.shorten_block_hash() %>
        </div>
        <div>
          <div class="list-h">Deployed At</div>
          <div>22h</div>
        </div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{class: _, view: "proxied-contracts"}) do
    ~H"""
    <div class="table-th !pt-7 border-t border-gray-700 grid-4">
      <div>Contract Address</div>
      <div>Type</div>
      <div>Class Hash</div>
      <div>Deployed At</div>
    </div>
    <%= for _ <- 0..10 do %>
      <div class="grid-4 custom-list-item">
        <div>
          <%= Utils.shorten_block_hash(
            "0x02eb7823cce8b6e15c027b509a8d1a7e3d2afc4ec32e892902c67e4abd4beb81"
          ) %>
        </div>
        <div>ERC20</div>
        <div>
          <%= "0x06e681a4da193cfd86e28a2879a17f4aedb4439d61a4a776b1e5686e9a4f96b2"
          |> Utils.shorten_block_hash() %>
        </div>
        <div>22h</div>
      </div>
    <% end %>
    """
  end

  def render_info(assigns = %{class: _block, view: "overview"}) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div>Class Hash</div>
      <div class="cols-span-3">
        <%= "0x06E681A4DA193CFD86E28A2879A17F4AEDB4439D61A4A776B1E5686E9A4F96B2"
        |> Utils.shorten_block_hash() %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared By Contract Address</div>
      <div class="cols-span-3">
        <%= "0x06E681A4DA193CFD86E28A2879A17F4AEDB4439D61A4A776B1E5686E9A4F96B2"
        |> Utils.shorten_block_hash() %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared At Transaction Hash</div>
      <div class="cols-span-3">
        <%= "0x06E681A4DA193CFD86E28A2879A17F4AEDB4439D61A4A776B1E5686E9A4F96B2"
        |> Utils.shorten_block_hash() %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared At</div>
      <div class="cols-span-3">July 4, 2023 at 7:10:11 PM GMT-3</div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Class Version</div>
      <div class="cols-span-3">Cairo 1.0</div>
    </div>
    """
  end

  def render_info(assigns = %{class: _block, view: "code"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
