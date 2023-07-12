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
    <div class="flex justify-center items-center pt-14">
      <h1 class="text-white text-4xl font-mono">Message Detail</h1>
    </div>
    <table>
      <thead>
        <ul>
          <li>
            Message Log ID 0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5_117_284_2
          </li>
          <li>Message Hash 0x5d29af220b92806d04896b6aabe719bf3da66da7bcdc4136ab78b0fefce08b26</li>
          <li>Type CONSUMED_ON_L1</li>
          <li>Message Direction L2 -> L1</li>
          <li>
            L1 Transaction Hash 0xa6fa8326f220bd4ed2a77eab4fc79cd9b93a6b89207a07af16a5c3cca0291ed5
          </li>
          <li>L1 Block Hash 0x93f4c763b869dd008594f8a976c7f0bb60942db7bf314a70339e7e8c94fcfd1a</li>
          <li>L1 Block Number 17630003</li>
          <li>L1 Address 0xc662c410c0ecf747543f5ba90660f6abebd9c8c4</li>
          <li>Timestamp July 5, 2023 at 5:17:35 PM GMT-3</li>
          Message Details
          <table>
            <thead>
              <ul>
                <li>
                  From L2 Contract Address 0x073314940630fd6dcda0d772d4c972c4e0a9946bef9dabf4ef84eda8ef542b82
                </li>
                <li>To L1 Contract Address 0xae0ee0a63a2ce6baeeffe56e7714fb4efe48d419</li>
                <li>Payload</li>
              </ul>
            </thead>
          </table>
        </ul>
      </thead>
    </table>
    """
  end

  def mount(_params = %{"identifier" => identifier}, _session, socket) do
    assigns = [
      message: nil
    ]

    {:ok, assign(socket, assigns)}
  end
end
