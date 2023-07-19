defmodule StarknetExplorerWeb.BlockDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  defp block_detail_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between mb-5 lg:mb-0">
      <h2>Block <span class="font-semibold">#<%= @block["block_number"] %></span></h2>
      <div class="text-gray-400">
        <%= @block["timestamp"]
        |> DateTime.from_unix()
        |> then(fn {:ok, time} -> time end)
        |> Calendar.strftime("%c") %> UTC
      </div>
    </div>
    <div
      id="dropdown"
      class="dropdown relative bg-[#232331] p-5 mb-5 rounded-md lg:hidden"
      phx-hook="Network"
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
    </div>
    """
  end

  @impl true
  def mount(_params = %{"number_or_hash" => param}, _session, socket) do
    {:ok, block} =
      case num_or_hash(param) do
        :hash ->
          Rpc.get_block_by_hash(param)

        :num ->
          {num, ""} = Integer.parse(param)
          Rpc.get_block_by_number(num)
      end

    assigns = [
      block: block,
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
      <%= block_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{block: _, view: "transactions"}) do
    ~H"""
    <div class="grid-3 table-th !pt-7 border-t border-gray-700">
      <div>Hash</div>
      <div>Type</div>
      <div>Version</div>
    </div>
    <%= for _transaction = %{"transaction_hash" => hash, "type" => type, "version" => version} <- @block["transactions"] do %>
      <div class="grid-3 custom-list-item">
        <div>
          <div class="list-h">Hash</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{hash}"}
            phx-hook="Copy"
          >
            <div class="relative">
              <div class="break-all text-hover-blue"><%= Utils.shorten_block_hash(hash) %></div>
              <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
                <div class="relative">
                  <img class="copy-btn copy-text w-4 h-4" src={~p"/images/copy.svg"} data-text={hash} />
                  <img
                    class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                    src={~p"/images/check-square.svg"}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div>
          <div class="list-h">Type</div>
          <div>
            <span class={"#{if type == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
              <%= type %>
            </span>
          </div>
        </div>
        <div>
          <div class="list-h">Version</div>
          <div><%= version %></div>
        </div>
      </div>
    <% end %>
    """
  end

  # TODO:
  # Do not hardcode:
  # - Total Execeution Resources
  # - Gas Price
  def render_info(assigns = %{block: _block, view: "overview"}) do
    ~H"""
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Hash</div>
      <div
        class="copy-container col-span-3 text-hover-blue"
        id={"copy-block-hash-#{@block["block_number"]}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block["block_hash"]) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block["block_hash"]}
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
    <div class="grid-4 custom-list-item">
      <div class="block-label">Block Status</div>
      <div class="col-span-3">
        <span class={"#{if @block["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if @block["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if @block["status"] == "PENDING", do: "pink-label"}"}>
          <%= @block["status"] %>
        </span>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">State Root</div>
      <div
        class="copy-container col-span-3"
        id={"copy-block-root-#{@block["block_number"]}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block["new_root"]) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block["new_root"]}
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
    <div class="grid-4 custom-list-item">
      <div class="block-label">Parent Hash</div>
      <div
        class="copy-container col-span-3"
        id={"copy-block-parent-#{@block["block_number"]}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block["parent_hash"]) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block["parent_hash"]}
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
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Sequencer Address
      </div>
      <div
        class="copy-container col-span-3 text-hover-blue"
        id={"copy-block-sequencer-#{@block["block_number"]}"}
        phx-hook="Copy"
      >
        <div class="relative">
          <%= Utils.shorten_block_hash(@block["sequencer_address"]) %>
          <div class="absolute top-1/2 -right-6 tranform -translate-y-1/2">
            <div class="relative">
              <img
                class="copy-btn copy-text w-4 h-4"
                src={~p"/images/copy.svg"}
                data-text={@block["sequencer_address"]}
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
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Gas Price
      </div>
      <div class="col-span-3">
        <div class="flex flex-col lg:flex-row items-start lg:items-center gap-2">
          <div class="gray-label text-sm">Mocked</div>
          <div class="break-all bg-se-cash-green/10 text-se-cash-green rounded-full px-4 py-1">
            <%= "0.000000017333948464 ETH" %>
          </div>
        </div>
      </div>
    </div>
    <div class="grid-4 custom-list-item">
      <div class="block-label">
        Total execution resources
      </div>
      <div class="col-span-3">
        <div class="flex flex-col lg:flex-row items-start lg:items-center gap-2">
          <div class="gray-label text-sm">Mocked</div>
          <%= 543_910 %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
