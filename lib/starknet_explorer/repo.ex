defmodule StarknetExplorer.Repo do
  use Ecto.Repo,
    otp_app: :starknet_explorer,
    adapter: Ecto.Adapters.SQLite3
end
