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
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Log ID</div>
        <div class="col-span-3">
          <%= "0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5_117_284_2"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Hash</div>
        <div class="col-span-3">
          <%= "0x5d29af220b92806d04896b6aabe719bf3da66da7bcdc4136ab78b0fefce08b26"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Type</div>
        <div class="col-span-3">CONSUMED_ON_L1</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Message Direction</div>
        <div class="col-span-3">L2 -> L1</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Transaction Hash</div>
        <div class="col-span-3">
          <%= "0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Block Hash</div>
        <div class="col-span-3">
          <%= "0x93f4c763b869dd008594f8a976c7f0bb60942db7bf314a70339e7e8c94fcfd1a"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Block Number</div>
        <div class="col-span-3">17630003</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Address</div>
        <div class="col-span-3">
          <%= "0xc662c410c0ecf747543f5ba90660f6abebd9c8c4"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Timestamp</div>
        <div class="col-span-3">July 5, 2023 at 5:17:35 PM GMT-3</div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0">Message Details</div>
        <div class="bg-black/10 p-5">
          <div class="custom-list-item grid-4 w-full !border-none">
            <div class="block-label !mt-0">From L2 Contract Address</div>
            <div>
              <%= "0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
          <div class="custom-list-item grid-4 w-full">
            <div class="block-label !mt-0">To L1 Contract Address</div>
            <div>
              <%= "0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419"
              |> Utils.shorten_block_hash() %>
            </div>
          </div>
        </div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0">Payload</div>
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
