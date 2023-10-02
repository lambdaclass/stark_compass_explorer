defmodule StarknetExplorerWeb.ClassDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Class
  # defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  # defp num_or_hash(_num), do: :num

  defp class_detail_header(assigns) do
    ~H"""
    <div class="flex flex-row justify-between lg:justify-start gap-5 items-baseline pb-5 lg:pb-0">
      <div class="flex flex-col lg:flex-row gap-2 items-baseline">
        <h2>Class</h2>
        <div
          class="copy-container break-all pr-10 lg:pr-0"
          id={"class-header-#{@class.class_hash}"}
          phx-hook="Copy"
        >
          <div class="relative">
            <div class="font-semibold">
              <%= @class.class_hash %>
            </div>
            <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
              <div class="relative">
                <img
                  class="copy-btn copy-text w-4 h-4"
                  src={~p"/images/copy.svg"}
                  data-text={@class.class_hash}
                />
                <img
                  class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                  src={~p"/images/check-square.svg"}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
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
        class={"option #{if assigns.view == "deployed-contracts", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent hidden"}"}
        phx-click="select-view"
        ,
        phx-value-view="deployed-contracts"
      >
        Deployed Contracts
      </div>
      <div
        class={"option #{if assigns.view == "proxied-contracts", do: "lg:!border-b-se-blue", else: "lg:border-b-transparent hidden"}"}
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
  def mount(_params = %{"hash" => hash}, _session, socket) do
    class = Class.get_by_hash(hash, socket.assigns.network)

    assigns = [
      class: class,
      view: "overview"
    ]

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

  def render_info(assigns = %{view: "overview"}) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div>Class Hash</div>
      <div class="cols-span-3">
        <%= Utils.shorten_block_hash(@class.class_hash) %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared By Contract Address</div>
      <div class="cols-span-3">
        <%= Utils.shorten_block_hash(@class.declared_by_contract_address) %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared At Transaction Hash</div>
      <div class="cols-span-3">
        <a
          href={
            Utils.network_path(
              @network,
              "transactions/#{@class.declared_at_transaction_hash}"
            )
          }
          class="text-se-blue"
        >
          <span>
            <%= Utils.shorten_block_hash(@class.declared_at_transaction_hash) %>
          </span>
        </a>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Declared At</div>
      <div class="cols-span-3">
        <%= Utils.format_timestamp(@class.timestamp) %>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div>Class Version</div>
      <div class="cols-span-3">
        <%= Utils.format_version(@class.version) %>
      </div>
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
