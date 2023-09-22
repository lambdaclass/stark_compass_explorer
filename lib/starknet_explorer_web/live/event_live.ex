defmodule StarknetExplorerWeb.EventDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <div class="flex flex-col lg:flex-row gap-2 items-baseline pb-5">
        <h2>Event</h2>
        <div class="font-semibold">
          <%= "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac_1"
          |> Utils.shorten_block_hash() %>
        </div>
        <span class="gray-label text-sm">Mocked</span>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Event ID</div>
        <div>
          <%= "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac_1"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Hash</div>
        <div>
          <a
            href={
              Utils.network_path(
                @network,
                "blocks/0x014570bdb1ed38e71bb11709b2fff208101d74231c1b973bd5d1e3ab717c659a"
              )
            }
            class="text-hover-blue"
          >
            <span> 0x014570bdb1ed38e71bb11709b2fff208101d74231c1b973bd5d1e3ab717c659a </span>
          </a>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Block Number</div>
        <div>98369</div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Transaction Hash</div>
        <div>
          <%= "0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">Contract Address</div>
        <div>
          <%= "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Block Hash</div>
        <div>
          <%= "0x93f4c763b869dd008594f8a976c7f0bb60942db7bf314a70339e7e8c94fcfd1a"
          |> Utils.shorten_block_hash() %>
        </div>
      </div>
      <div class="grid-4 custom-list-item">
        <div class="block-label !mt-0">L1 Block Number</div>
        <div>17630003</div>
      </div>
      <div class="custom-list-item">
        <div class="block-label !mt-0 lg:pb-5">Event Data</div>
        <div class="bg-black/10 p-5">
          <div class="grid-3 w-full table-th">
            <div>Input</div>
            <div>Type</div>
            <div>Value</div>
          </div>
          <%= for _idx <- 0..0 do %>
            <div class="grid-3 w-full custom-list-item">
              <div>
                <div class="list-h">Input</div>
                <div>from_</div>
              </div>
              <div>
                <div class="list-h">Type</div>
                <div>felt</div>
              </div>
              <div>
                <div class="list-h">Value</div>
                <%= "0x4c97c4d367b88df2f29887043750ff189f539c28fe1fed331d3359b403a8bad"
                |> Utils.shorten_block_hash() %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params = %{"identifier" => _identifier}, _session, socket) do
    assigns = [
      event: nil
    ]

    {:ok, assign(socket, assigns)}
  end
end
