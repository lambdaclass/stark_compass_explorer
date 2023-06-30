defmodule StarknetExplorerWeb.HomeLive.Index do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorer.DateUtils

  def mount(_params, _session, socket) do
    Process.send(self(), :load_blocks, [])
    {:ok, assign(socket, :blocks, [])}
  end

  def render(assigns) do
    ~H"""
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
            <ul id={"block-#{block["block_number"]}"} class="grid gap-20 grid-cols-4  auto-cols-[minmax(0,1fr)] border-b-[0.5px] border-gray-600 last:border-none border-spacing-6">
              <li scope="row" class="py-4">
              <%= live_redirect(to_string(block["block_number"]),
                to: "/",
                class: "text-blue-500 hover:text-blue-700 underline-none font-medium"
              ) %>
            </li>
              <li scope="row" class="py-4">
              <%= live_redirect(shorten_block_hash(block["block_hash"]),
                to: "/",
                class: "text-blue-500 hover:text-blue-700 underline-none font-medium",
                title: block["block_hash"]
              ) %>
            </li>
              <li scope="row" class="py-4"><%= block["status"] %></li>
              <li scope="row" class="py-4"><%= get_block_age(block) %></li>
          </ul>
          <% end %>
          </div>
      </div>
    """
  end

  @impl true
  def handle_info(:load_blocks, socket) do
    {:noreply, assign(socket, :blocks, list_blocks())}
  end

  defp get_latest_block_number() do
    {:ok, latest_block} = Rpc.get_latest_block()
    latest_block["block_number"]
  end

  defp list_blocks() do
    Enum.reverse(list_blocks(get_latest_block_number(), 15, []))
  end

  defp list_blocks(_block_number, 0, acc) do
    acc
  end

  defp list_blocks(block_number, remaining, acc) do
    {:ok, block} = Rpc.get_block_by_number(block_number)
    prev_block_number = block_number - 1
    list_blocks(prev_block_number, remaining - 1, [block | acc])
  end

  defp get_block_age(block) do
    %{minutes: minutes, hours: hours, days: days} =
      DateUtils.calculate_time_difference(block["timestamp"])

    case days do
      0 ->
        case hours do
          0 -> "#{minutes} min"
          _ -> "#{hours} h"
        end

      _ ->
        "#{days} d"
    end
  end

  defp shorten_block_hash(block_hash) do
    "#{String.slice(block_hash, 0, 6)}...#{String.slice(block_hash, -4, 4)}"
  end
end
