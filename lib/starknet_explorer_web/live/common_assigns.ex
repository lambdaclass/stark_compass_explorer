defmodule StarknetExplorerWeb.Live.CommonAssigns do
  import Phoenix.Component

  def on_mount(:network, params = %{"network" => network}, session, socket) do
    socket =
      case network do
        network when network in ["mainnet", "testnet", "testnet2"] ->
          network =
            network
            |> String.to_existing_atom()

          assign(socket, :network, network)

        _ ->
          assign(socket, :network, :mainnet)
      end

    {:cont, socket}
  end
end
