defmodule StarknetExplorer.Blockchain.BlockchainSupervisor do
  use Supervisor
  alias StarknetExplorer.Blockchain.{ListenerSupervisor, UpdaterSupervisor, FetcherSupervisor}

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    fetcher_supervisor =
      if System.get_env("ENABLE_FETCHER") == "true" do
        [FetcherSupervisor]
      else
        []
      end

    updater_supervisor =
      if System.get_env("ENABLE_UPDATER") == "true" do
        [UpdaterSupervisor]
      else
        []
      end

    listener_supervisor =
      if System.get_env("ENABLE_LISTENER") == "true" do
        [ListenerSupervisor]
      else
        []
      end

    children =
      listener_supervisor ++ updater_supervisor ++ fetcher_supervisor

    Supervisor.init(children, strategy: :one_for_one)
  end
end
