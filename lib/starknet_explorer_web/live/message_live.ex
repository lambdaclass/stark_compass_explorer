defmodule StarknetExplorerWeb.MessageDetailLive do
  use StarknetExplorerWeb, :live_view
  alias StarknetExplorerWeb.Utils
  alias StarknetExplorer.Message
  alias StarknetExplorerWeb.CoreComponents

  embed_templates "messages/*"

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, StarknetExplorerWeb.SearchLive,
      id: "search-bar",
      flash: @flash,
      session: %{"network" => @network}
    ) %>
    <div class="max-w-7xl mx-auto bg-container p-4 md:p-6 rounded-md">
      <.message_info message={assigns.message} network={assigns.network} />
    </div>
    """
  end

  def message_info(assigns)

  def mount(_params = %{"identifier" => hash}, _session, socket) do
    message = Message.get_by_hash(hash, socket.assigns.network)
    IO.inspect(message)

    message =
      case Message.is_l2_to_l1(message) do
        false ->
          tx = StarknetExplorer.Transaction.get_by_hash(message.transaction_hash)

          decimal_nonce =
            case tx.nonce do
              nil -> nil
              nonce -> nonce |> String.replace("0x", "") |> String.to_integer(16)
            end

          message |> Map.put(:selector, tx.entry_point_selector) |> Map.put(:nonce, decimal_nonce)

        _ ->
          message
      end

    assigns = [
      message: message
    ]

    {:ok, assign(socket, assigns)}
  end
end
