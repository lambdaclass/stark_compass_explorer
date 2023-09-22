defmodule StarknetExplorer.Repo do
  adapter =
    if System.get_env("DB_TYPE") == "postgresql" do
      Ecto.Adapters.Postgres
    else
      Ecto.Adapters.SQLite3
    end

  use Ecto.Repo,
    otp_app: :starknet_explorer,
    adapter: adapter

  use Scrivener, page_size: 30
end
