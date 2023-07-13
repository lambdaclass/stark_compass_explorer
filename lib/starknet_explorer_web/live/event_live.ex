defmodule StarknetExplorerWeb.EventDetailLive do
  use StarknetExplorerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash
    ) %>
    <div class="flex justify-center items-center pt-14">
      <h1 class="text-white text-4xl font-mono">Event Detail</h1>
    </div>
    <table>
      <thead>
        <ul>
          <li>
            Event ID 0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac_1
          </li>
          <li>Block Hash 0x014570bdb1ed38e71bb11709b2fff208101d74231c1b973bd5d1e3ab717c659a</li>
          <li>Block Number 98369</li>
          <li>Transaction Hash 0x01b4d24a461851e8eb9924369b5d9e23e79e8bbea6abc93eae4323462a25ddac</li>
          <li>Contract Address 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7</li>
          <li>L1 Block Hash 0x93f4c763b869dd008594f8a976c7f0bb60942db7bf314a70339e7e8c94fcfd1a</li>
          <li>L1 Block Number 17630003</li>
          Event Data
          <div class="table-block">
            <ul class="transactions-grid table-th">
              <li class="col-span-2">Input</li>
              <li class="col-span-2">Type</li>
              <li class="col-span-2">Value</li>
            </ul>
            <div id="classes">
              <%= for idx <- 0..0 do %>
                <ul id={"message-#{idx}"} class="transactions-grid border-t border-gray-600">
                  <li class="col-span-2">
                    from_
                  </li>
                  <li class="col-span-2">felt</li>
                  <li class="col-span-2">
                    "0x4c97c4d367b88df2f29887043750ff189f539c28fe1fed331d3359b403a8bad">
                  </li>
                </ul>
              <% end %>
            </div>
          </div>
        </ul>
      </thead>
    </table>
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
