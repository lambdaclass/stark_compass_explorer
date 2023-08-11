defmodule StarknetExplorerWeb.Live.CommonAssigns do
  import Phoenix.Component

  def on_mount(:network, params, _session, socket) do
    socket =
      case params do
        %{"network" => network} when network in ["mainnet", "testnet", "testnet2"] ->
          network = String.to_existing_atom(network)

          assign(socket, :network, network)

        _ ->
          assign(socket, :network, :mainnet)
      end

    {:cont, socket}
  end
end
