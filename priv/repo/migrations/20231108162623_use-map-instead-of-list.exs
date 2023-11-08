defmodule :"Elixir.StarknetExplorer.Repo.Migrations.Use-map-instead-of-list" do
  use Ecto.Migration

  def change do
    alter table(:transaction_receipts) do
      remove :execution_resources
    end

    alter table(:transaction_receipts) do
      add :execution_resources, :map
    end
  end
end
