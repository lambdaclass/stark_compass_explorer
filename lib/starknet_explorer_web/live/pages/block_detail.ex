defmodule StarknetExplorerWeb.BlockDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils
  defp num_or_hash(<<"0x", _rest::binary>>), do: :hash
  defp num_or_hash(_num), do: :num

  defp block_detail_header(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row justify-between">
      <h2>Block <span class="font-semibold">#<%= @block["block_number"] %></span></h2>
      <div class="text-gray-400">
        <%= @block["timestamp"]
        |> DateTime.from_unix()
        |> then(fn {:ok, time} -> time end)
        |> Calendar.strftime("%c") %> UTC
      </div>
    </div>
    <div class="flex gap-5 mt-8">
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.view == "overview", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="overview"
      >
        Overview
      </div>
      <div
        class={"btn border-b pb-3 px-3 transition-all duration-300 #{if assigns.view == "transactions", do: "border-b-se-blue", else: "border-b-transparent"}"}
        phx-click="select-view"
        ,
        phx-value-view="transactions"
      >
        Transactions
      </div>
    </div>
    """
  end

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
    <div class="max-w-4xl mx-auto bg-container p-4 md:p-8 rounded-md">
      <%= block_detail_header(assigns) %>
      <%= render_info(assigns) %>
    </div>
    """
  end

  def render_info(assigns = %{block: block, view: "transactions"}) do
    ~H"""
    <div>
      <div class="hidden md:grid grid-cols-3 gap-10 px-3 pt-5 pb-3 font-semibold border-t border-t-gray-500">
        <div>Hash</div>
        <div>Type</div>
        <div>Version</div>
      </div>
      <%= for _transaction = %{"transaction_hash" => hash, "type" => type, "version" => version} <- @block["transactions"] do %>
        <div class="grid md:grid-cols-3 gap-2 md:gap-10 px-3 pt-3 mb-3 border-t border-t-gray-500">
          <div class="list-h">Hash</div>
          <div
            class="flex gap-2 items-center copy-container"
            id={"copy-transaction-hash-#{hash}"}
            phx-hook="Copy"
          >
            <div class="break-all text-hover-blue"><%= Utils.shorten_block_hash(hash) %></div>
            <div class="relative">
              <img class="copy-btn copy-text w-4 h-4" src={~p"/images/copy.svg"} data-text={hash} />
              <img
                class="copy-check absolute top-0 left-0 w-4 h-4 opacity-0 pointer-events-none"
                src={~p"/images/check-square.svg"}
              />
            </div>
          </div>
          <div class="list-h">Type</div>
          <div>
            <span class={"#{if type == "INVOKE", do: "violet-label", else: "lilac-label"}"}>
              <%= type %>
            </span>
          </div>
          <div class="list-h">Version</div>
          <div><%= version %></div>
        </div>
      <% end %>
    </div>
    """
  end

  # TODO:
  # Do not hardcode:
  # - Total Execeution Resources
  # - Gas Price
  def render_info(assigns = %{block: _block, view: "overview"}) do
    ~H"""
    <div>
      <div class="block-overview">
        <div class="block-label">Block Hash</div>
        <div
          class="col-span-3 break-all text-hover-blue break-all flex gap-2 items-center copy-container"
          id={"copy-block-hash-#{@block["block_number"]}"}
          phx-hook="Copy"
        >
          <%= Utils.shorten_block_hash(@block["block_hash"]) %>
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
      <div class="block-overview">
        <div class="block-label">Block Status</div>
        <div class="col-span-3">
          <span class={"#{if @block["status"] == "ACCEPTED_ON_L2", do: "green-label"} #{if @block["status"] == "ACCEPTED_ON_L1", do: "blue-label"} #{if @block["status"] == "PENDING", do: "pink-label"}"}>
            <%= @block["status"] %>
          </span>
        </div>
      </div>
      <div class="block-overview">
        <div class="block-label">State Root</div>
        <div
          class="col-span-3 break-all break-all flex gap-2 items-center copy-container"
          id={"copy-block-root-#{@block["block_number"]}"}
          phx-hook="Copy"
        >
          <%= Utils.shorten_block_hash(@block["new_root"]) %>
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
      <div class="block-overview">
        <div class="block-label">Parent Hash</div>
        <div
          class="col-span-3 break-all break-all flex gap-2 items-center copy-container"
          id={"copy-block-parent-#{@block["block_number"]}"}
          phx-hook="Copy"
        >
          <%= Utils.shorten_block_hash(@block["parent_hash"]) %>
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
      <div class="block-overview">
        <div class="block-label">
          Sequencer Address
        </div>
        <div
          class="col-span-3 break-all text-se-violet break-all flex gap-2 items-center copy-container"
          id={"copy-block-sequencer-#{@block["block_number"]}"}
          phx-hook="Copy"
        >
          <%= Utils.shorten_block_hash(@block["sequencer_address"]) %>
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
      <div class="block-overview">
        <div class="block-label">
          Gas Price
        </div>
        <div class="col-span-3">
          <span class="break-all bg-se-cash-green/10 text-se-cash-green rounded-full px-4 py-1">
            <%= "0.000000017333948464 ETH" %>
          </span>
        </div>
      </div>
      <div class="block-overview">
        <div class="block-label">
          Total execution resources
        </div>
        <div class="col-span-3"><%= 543_910 %></div>
      </div>
    </div>
    """
  end

  def handle_event("select-view", %{"view" => view}, socket) do
    socket = assign(socket, :view, view)
    {:noreply, socket}
  end
end
