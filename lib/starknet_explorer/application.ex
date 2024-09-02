defmodule StarknetExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  # import Cachex.Spec
  use Application

  @impl true
  def start(_type, _args) do
    mainnet_state_sync =
      if System.get_env("DISABLE_MAINNET_SYNC") == "true" do
        []
      else
        # Start the State Sync System server for mainnet.
        [
          Supervisor.child_spec(
            {StarknetExplorer.Blockchain.StateSyncSystem,
             [network: :mainnet, name: :mainnet_state_sync]},
            id: :mainnet_state_sync
          )
        ]
      end

    sepolia_state_sync =
      if System.get_env("DISABLE_SEPOLIA_SYNC") == "true" do
        []
      else
        # Start the State Sync System server for sepolia.
        [
          Supervisor.child_spec(
            {StarknetExplorer.Blockchain.StateSyncSystem,
             [network: :sepolia, name: :sepolia_state_sync]},
            id: :sepolia_state_sync
          )
        ]
      end

    children =
      [
        # Start the Telemetry supervisor
        StarknetExplorerWeb.Telemetry,
        # Start the Ecto repository
        StarknetExplorer.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: StarknetExplorer.PubSub},
        # Start Finch
        {Finch, name: StarknetExplorer.Finch},
        # Start the Endpoint (http/https)
        StarknetExplorerWeb.Endpoint,
        # Start a worker by calling: StarknetExplorer.Worker.start_link(arg)
        # {StarknetExplorer.Worker, arg}
        StarknetExplorer.IndexCache
      ] ++ sepolia_state_sync ++ mainnet_state_sync

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StarknetExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StarknetExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # defp cache_supervisor_spec(network) do
  #   # Active block cache
  #   active_block_cache_spec =
  #     Supervisor.child_spec(
  #       Cachex.child_spec(
  #         name: :"#{network}_block_cache",
  #         limit: 1000,
  #         id: :"#{network}_block_cache",
  #         warmers: [
  #           warmer(
  #             module: StarknetExplorer.Cache.BlockWarmer,
  #             state: %{network: network},
  #             async: true
  #           )
  #         ]
  #       ),
  #       id: :"#{network}_block_cache"
  #     )

  #   tx_cache_spec =
  #     Supervisor.child_spec(
  #       Cachex.child_spec(name: :"#{network}_tx_cache", limit: 5000, id: :"#{network}_tx_cache"),
  #       id: :"#{network}_tx_cache"
  #     )

  #   # Passive cache for general requests
  #   request_cache =
  #     Supervisor.child_spec(
  #       Cachex.child_spec(
  #         name: :"#{network}_request_cache",
  #         limit: 5000,
  #         id: :"#{network}_request_cache",
  #         policy: Cachex.Policy.LRW
  #       ),
  #       id: :"#{network}_request_cache"
  #     )

  #   [active_block_cache_spec, tx_cache_spec, request_cache]
  # end
end
