defmodule StarknetExplorer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  import StarknetExplorer.Utils
  import Cachex.Spec
  use Application

  @impl true
  def start(_type, _args) do
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
        # Active block cache
        Supervisor.child_spec(
          Cachex.child_spec(
            name: :block_cache,
            limit: 1000,
            id: :block_cache,
            warmers: [
              warmer(module: StarknetExplorer.Cache.BlockWarmer, state: %{})
            ]
          ),
          id: :block_cache
        ),
        Supervisor.child_spec(
          Cachex.child_spec(name: :tx_cache, limit: 5000, id: :tx_cache),
          id: :tx_cache
        ),
        # Passive cache for general requests
        Supervisor.child_spec(
          Cachex.child_spec(
            name: :request_cache,
            limit: 5000,
            id: :request_cache,
            policy: Cachex.Policy.LRW
          ),
          id: :request_cache
        )
        # Start a worker by calling: StarknetExplorer.Worker.start_link(arg)
        # {StarknetExplorer.Worker, arg}
      ] ++
        if_prod do
          # TODO: Uncomment when it's ready
          # [StarknetExplorer.BlockFetcher]
          []
        else
          []
        end

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
end
