defmodule StarknetExplorerWeb.ClassDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorerWeb.CoreComponents

  defp class_detail_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Class</h2>
      <%= if !is_nil(@class) do %>
        <div class="font-normal text-gray-400 mt-2 lg:mt-0">
          <%= @class.timestamp
          |> DateTime.from_unix()
          |> then(fn {:ok, time} -> time end)
          |> Calendar.strftime("%c") %> UTC
        </div>
      <% end %>
    </div>
    """
  end

  def dropdown_menu(assigns) do
    ~H"""
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
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
        class={"option #{if assigns.view == "deployed_contracts", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="proxied_contracts"
      >
        Deployed Contracts
      </div>
      <div
        class={"option #{if assigns.view == "proxied_contracts", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="proxied_contracts"
      >
        Proxied Contracts
      </div>
      <div
        class={"option #{if assigns.view == "code", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
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
    class = StarknetExplorer.Class.get_by_hash(hash, socket.assigns.network)

    assigns = [
      class: class,
      view: "overview"
    ]

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <%= class_detail_header(assigns) %>
      <%= class_dropdown(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  defp class_dropdown(assigns) do
    ~H"""
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-2 rounded-md lg:hidden"
      phx-hook="Dropdown"
    >
      <span class="networkSelected capitalize"><%= assigns.view %></span>
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
        class={"option #{if assigns.view == "deployed_contracts", do: "lg:!border-b-se-blue text-white", else: "text-gray-400 lg:border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="deployed_contracts"
      >
        Deployed Contracts
      </div>
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

  def render_info(assigns = %{class: nil, view: "overview"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">
      The class was not found.
      We are still syncing the blockchain, please try again later.
    </div>
    """
  end

  def render_info(assigns = %{class: _block, view: "overview"}) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label !mt-0">Class Hash</div>
      <div class="block-data">
        <div class="hash flex">
          <%= @class.hash %>
          <CoreComponents.copy_button text={@class.hash} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label !mt-0">Declared by Address</div>
      <div class="block-data">
        <div class="hash flex">
          <a
            href={
              Utils.network_path(
                @network,
                "contracts/#{@class.declared_by_address}"
              )
            }
            class="text-hover-link break-all"
          >
            <span><%= @class.declared_by_address %></span>
          </a>
          <CoreComponents.copy_button text={@class.declared_by_address} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label !mt-0">Declared at Transaction</div>
      <div class="block-data">
        <div class="hash flex">
          <a
            href={
              Utils.network_path(
                @network,
                "transactions/#{@class.declared_at_transaction}"
              )
            }
            class="text-hover-link break-all"
          >
            <span><%= @class.declared_at_transaction %></span>
          </a>
          <CoreComponents.copy_button text={@class.declared_at_transaction} />
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label !mt-0">Type</div>
      <CoreComponents.render_class_types class={@class} />
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label !mt-0">Version</div>
      <div class="block-data">
        <div class="flex">
          Cairo <%= @class.version %>
        </div>
      </div>
    </div>
    """
  end

  def render_info(assigns = %{class: _block, view: "code"}) do
    ~H"""
    <div class="text-gray-500 text-xl border-t border-t-gray-700 pt-5">In development</div>
    """
  end

  def render_info(assigns = %{class: _block, view: "deployed_contracts"}) do
    ~H"""
    <div class="table-th !pt-7 grid-3">
      <div>Contract Address</div>
      <div>Class Hash</div>
      <div>Age</div>
    </div>
    <%= if @page.total_entries == 0 do %>
      <div class="grid-3 custom-list-item">
        <div class="text-gray-500 text-xl pt-5">
          No events found
        </div>
      </div>
    <% else %>
      <%= for contract <- @page.entries do %>
        <div class="custom-list-item grid-3">
          <div>
            <div class="list-h">Contract Address</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "contracts/#{contract.address}")}
                  class="text-hover-link"
                >
                  <%= contract.address |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={contract.address} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Class Hash</div>
            <div class="block-data">
              <div class="hash flex">
                <a
                  href={Utils.network_path(@network, "classes/#{@class.hash}")}
                  class="text-hover-link"
                >
                  <%= @class.hash |> Utils.shorten_block_hash() %>
                </a>
                <CoreComponents.copy_button text={@class.hash} />
              </div>
            </div>
          </div>
          <div>
            <div class="list-h">Age</div>
            <%= contract.timestamp
            |> DateTime.from_unix()
            |> then(fn {:ok, time} -> time end)
            |> Calendar.strftime("%c") %> UTC
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

  @impl true
  def handle_event("select-view", %{"view" => "deployed_contracts"}, socket) do
    page =
      StarknetExplorer.Contract.get_page_by_class_hash(
        %{page_number: 0},
        socket.assigns.class.hash,
        socket.assigns.network
      )

    assigns = [
      page: page,
      view: "deployed_contracts",
      active_pagination_id: "deployed_contracts"
    ]

    {:noreply, assign(socket, assigns)}
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
