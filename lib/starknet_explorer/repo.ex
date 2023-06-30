defmodule StarknetExplorer.Repo do
  use Ecto.Repo,
    otp_app: :starknet_explorer,
    adapter: Ecto.Adapters.Postgres
end
