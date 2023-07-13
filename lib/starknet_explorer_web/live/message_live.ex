defmodule StarknetExplorerWeb.MessageDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorer.Rpc
  alias StarknetExplorerWeb.Utils

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="flex flex-col lg:flex-row lg:gap-2 items-baseline pb-5">
        <h2>Message</h2>
        <div class="font-semibold">
          <%= "0x5d29af220b92806d04896b6aabe719bf3da66da7bcdc4136ab78b0fefce08b26"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">Message Log ID</div>
        <div>
          <%= "0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5_117_284_2"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">Message Hash</div>
        <div>
          <%= "0x5d29af220b92806d04896b6aabe719bf3da66da7bcdc4136ab78b0fefce08b26"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">Type</div>
        <div>CONSUMED_ON_L1</div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">Message Direction</div>
        <div>L2 -> L1</div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">L1 Transaction Hash</div>
        <div>
          <%= "0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">L1 Block Hash</div>
        <div>
          <%= "0x93f4c763b869dd008594f8a976c7f0bb60942db7bf314a70339e7e8c94fcfd1a"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">L1 Block Number</div>
        <div>17630003</div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">L1 Address</div>
        <div>
          <%= "0xc662c410c0ecf747543f5ba90660f6abebd9c8c4"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item !pt-0">
        <div class="text-gray-400 lg:text-white">Timestamp</div>
        <div>July 5, 2023 at 5:17:35 PM GMT-3</div>
      </div>
      <div class="custom-list-item">
        <div class="text-gray-400 lg:text-white">Message Details</div>
        <div class="bg-black/10 p-5">
          <div class="custom-list-item grid-4 w-full !border-none">
            <div class="text-gray-400 lg:text-white">From L2 Contract Address</div>
            <div>
              <%= "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
          <div class="custom-list-item grid-4 w-full">
            <div class="text-gray-400 lg:text-white">To L1 Contract Address</div>
            <div>
              <%= "0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
        </div>
      </div>
      <div class="custom-list-item">
        <div class="text-gray-400 lg:text-white">Payload</div>
        <div class="bg-black/10 p-5">
          <div class="w-full grid-8 table-th">
            <div>Index</div>
            <div class="col-span-7">Value</div>
          </div>
          <div class="w-full grid-8 custom-list-item">
            <div>
              <div class="list-h">Index</div>
              <div class="break-all">0</div>
            </div>
            <div>
              <div class="list-h">Value</div>
              <div class="break-all col-span-7">
                <%= "0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419" |> Utils.shorten_block_hash() %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params = %{"identifier" => identifier}, _session, socket) do
    assigns = [
      message: nil
    ]

    {:ok, assign(socket, assigns)}
  end
end
