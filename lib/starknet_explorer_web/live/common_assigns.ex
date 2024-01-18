defmodule StarknetExplorerWeb.Live.CommonAssigns do
  import Phoenix.Component

  def on_mount(:network, params, _session, socket) do
    socket =
      case Map.get(params, "network") do
        network when network in ["testnet", "sepolia"] ->
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
