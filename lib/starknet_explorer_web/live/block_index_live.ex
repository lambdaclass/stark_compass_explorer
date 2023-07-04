defmodule StarknetExplorerWeb.BlockIndexLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center pt-14">
      <h1>Blocks</h1>
    </div>
    <div class="table-block bg-[#182635]">
      <div>
        <ul class="grid grid-cols-4 grid-flow-col text-lg gap-20 px-2 text-white/50">
          <li scope="col" class="py-5">Number</li>
          <li scope="col" class="py-5">Block Hash</li>
          <li scope="col" class="py-5">Status</li>
          <li scope="col" class="py-5">Age</li>
        </ul>
      </div>
      <div id="blocks" class="px-2">
        <%= for block <- @blocks do %>
          <ul
            id={"block-#{block["block_number"]}"}
            class="grid gap-20 grid-cols-4  auto-cols-[minmax(0,1fr)] border-b-[0.5px] border-gray-600 last:border-none border-spacing-6"
          >
            <li scope="row" class="py-4">
              <%= live_redirect(to_string(block["block_number"]),
                to: "/block/#{block["block_number"]}",
                class: "text-blue-500 hover:text-blue-700 underline-none font-medium"
              ) %>
            </li>
            <li scope="row" class="py-4">
              <%= live_redirect(Utils.shorten_block_hash(block["block_hash"]),
                to: "/block/#{block["block_hash"]}",
                class: "text-blue-500 hover:text-blue-700 underline-none font-medium",
                title: block["block_hash"]
              ) %>
            </li>
            <li scope="row" class="py-4"><%= block["status"] %></li>
            <li scope="row" class="py-4"><%= Utils.get_block_age(block) %></li>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])

    {:ok,
     assign(socket,
       blocks: [],
       latest_block: []
     )}
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply,
     assign(socket,
       blocks: Utils.list_blocks(),
       latest_block: Utils.get_latest_block_with_transactions()
     )}
  end
end
