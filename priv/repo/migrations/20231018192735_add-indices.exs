defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Add-indices" do
  use Ecto.Migration

  def change do
    if System.get_env("DB_TYPE") == "postgresql" do
      execute("create index event_from_address_index on events (from_address);")
      execute("create index transaction_sender_address_index on transactions (sender_address);")
      execute("create index contract_class_hash_index on contracts (class_hash);")
    end
  end
end
